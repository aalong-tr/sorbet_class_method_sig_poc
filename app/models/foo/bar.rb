# frozen_string_literal: true

module Foo
  class Bar < ApplicationRecord
    extend T::Sig

    self.table_name = "foo_bars"

    scope :irrelevant, -> { }
    # other scopes omitted for brevity

    sig { params(id: Integer).returns(Integer) }
    def self.method_one(id:)
      id
    end

    sig { params(id: Integer).returns(T.nilable(String)) }
    def self.method_two(id:)
      id.to_s
    end
  end
end
