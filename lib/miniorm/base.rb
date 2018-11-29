require 'miniorm/utility'
require 'miniorm/schema'
require 'miniorm/persistence'
require 'miniorm/connection'

module MiniORM
  class Base
    extend Persistence
    extend Schema
    extend Connection

    def initialize(options={})
      options = MiniORM::Utility.convert_keys(options)

      self.class.columns.each do |col|
        self.class.send(:attr_accessor, col)
        self.instance_variable_set("@#{col}", options[col])
      end
    end
  end
end