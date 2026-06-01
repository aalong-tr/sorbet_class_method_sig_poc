# sorbet_class_method_sig_poc

A minimal Rails engine gem that reproduces a `sorbet-runtime` bug where
`tapioca dsl` raises **"You called sig twice without declaring a method in
between"** when eager-loading a model that has consecutive `sig`/`def self.*`
pairs.

## Affected versions

| Gem | Version |
|-----|---------|
| Rails | 7.1.5.2 |
| sorbet-runtime | 0.6.13266 |
| sorbet-static | 0.6.13266 |
| tapioca | 0.19.1 |
| require-hooks | 0.4.0 |
| zeitwerk | 2.8.2 |

## Rails version compatibility

The bug is **specific to Rails 7.1.x**. Tested with the same sorbet/tapioca
versions against other Rails releases:

| Rails version | Result |
|---|---|
| **7.1.5.2** | 💥 Crashes — `sig called twice` |
| **7.2.3.1** | ✅ Passes |
| **8.0.5** | ✅ Passes |

Something in the Rails 7.1 → 7.2 initialization sequence changed how Zeitwerk
triggers eager loading relative to when `require-hooks` installs its `load_iseq`
interceptor. Under Rails 7.2+, `singleton_method_added` fires correctly and
each `sig` is consumed before the next one is reached. The exact Rails-side
change has not been pinpointed, but it is a strong signal that the root cause
is a **timing/ordering interaction** between the three components rather than
a standalone bug in any single gem.

## Reproducing the bug

```bash
bundle install

# Create the SQLite database and load the schema
RAILS_ENV=development bundle exec ruby -e "
  require_relative 'spec/dummy/config/environment'
  ActiveRecord::Base.establish_connection
  load File.expand_path('spec/dummy/db/schema.rb', Dir.pwd)
"

# Trigger the bug
RAILS_ENV=development bundle exec tapioca dsl
```

Expected output (the crash):

```
Loading DSL extension classes... Done
Loading Rails application...
Tapioca attempted to load the Rails application after encountering a
`config/application.rb` file, but it failed. ...
You called sig twice without declaring a method in between
...
sorbet-runtime-0.6.13266/.../types/private/methods/_methods.rb:56:in
  `declare_sig': You called sig twice without declaring a method in between
  (RuntimeError)
  from .../types/sig.rb:99:in `sig'
  from .../app/models/foo/bar.rb:17:in `<class:Bar>'
```

## The offending model

`app/models/foo/bar.rb` contains two perfectly ordinary `sig`/`def self.*`
pairs — nothing wrong with the Ruby itself:

```ruby
module Foo
  class Bar < ApplicationRecord
    extend T::Sig

    self.table_name = "foo_bars"

    scope :irrelevant, -> { }

    sig { params(id: Integer).returns(Integer) }
    def self.method_one(id:)
      id
    end

    sig { params(id: Integer).returns(T.nilable(String)) }  # ← crashes here
    def self.method_two(id:)
      id.to_s
    end
  end
end
```

Loading the same model outside of `tapioca dsl` works fine:

```bash
RAILS_ENV=development bundle exec ruby -e "
  require_relative 'spec/dummy/config/environment'
  Rails.application.eager_load!
  puts Foo::Bar.instance_methods(false).inspect
"
```

## Root cause

The crash is a **three-way interaction** between `sorbet-static`,
`require-hooks`, and `zeitwerk`. No single component is obviously wrong in
isolation.

### The load chain

1. `tapioca dsl` boots the Rails app from `spec/dummy`, which sets
   `config.eager_load = true`.
2. During `Rails.application.initialize!`, the Rails finisher calls
   `Zeitwerk::Loader.eager_load_all`, which iterates all registered autoload
   paths and calls `require` on each file — including
   `app/models/foo/bar.rb`.
3. That `require` is intercepted by **`require-hooks`** (a transitive
   dependency of `sorbet-static`) via its `load_iseq` hook, which
   re-evaluates the file content inside a native `eval` call rather than
   allowing Ruby's normal file-load path.

### Why the sig machinery breaks inside `load_iseq`

Sorbet-runtime's `sig { ... }` works by:

1. Setting a thread-local "pending sig" when `sig { ... }` is called.
2. Clearing it — and installing the runtime type-checking wrapper — inside
   a `singleton_method_added` (or `method_added`) callback that fires when
   the subsequent `def` is evaluated.

When `foo/bar.rb` is evaluated inside `require-hooks`'s `eval`/`load_iseq`
context, the `singleton_method_added` callback for `def self.method_one`
**does not properly clear the pending sig**. The exact mechanism is that the
`eval` context alters how Ruby dispatches the hook, so sorbet-runtime never
sees the `def` as "consuming" the first `sig`.

When the interpreter then reaches the second `sig { ... }` (line 17, for
`method_two`), sorbet-runtime still has the first sig registered as pending
and raises `RuntimeError: You called sig twice without declaring a method in
between`.

### Why it only happens under `tapioca dsl`

Running `require_relative 'spec/dummy/config/environment'` alone (even with
`eager_load!`) does **not** trigger the bug, because in that scenario
`require-hooks` is not yet installed as a `load_iseq` interceptor — it is
activated as a side-effect of `sorbet-static` being initialized inside the
tapioca process before the app boots.

## Project structure

```
.
├── app/models/foo/bar.rb          # The model with the offending sigs
├── lib/
│   ├── sorbet_class_method_sig_poc.rb
│   └── sorbet_class_method_sig_poc/
│       ├── engine.rb              # Rails::Engine (isolate_namespace Foo)
│       └── version.rb
├── sorbet/
│   ├── config
│   └── tapioca/
│       └── config.yml             # Sets app_root: spec/dummy for tapioca dsl
├── spec/dummy/                    # Minimal Rails host app that mounts the engine
│   ├── app/models/application_record.rb
│   ├── config/
│   │   ├── application.rb
│   │   ├── boot.rb
│   │   ├── database.yml
│   │   └── environment.rb
│   └── db/schema.rb
└── tapioca/require.rb
```
