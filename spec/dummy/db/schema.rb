# frozen_string_literal: true

ActiveRecord::Schema[7.1].define(version: 2024_01_01_000000) do
  create_table "foo_bars", force: :cascade do |t|
    t.timestamps
  end
end
