require 'miniorm/utility'
require 'miniorm/schema'
require 'miniorm/persistence'
require 'miniorm/selection'
require 'miniorm/connection'
require 'miniorm/collection'


module MiniORM
  class Base
    include Persistence
    extend Selection
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