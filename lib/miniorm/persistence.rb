require 'sqlite3'
require 'miniorm/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    unless self.id
      self.id = self.class.create(MiniORM::Utility.instance_variables_to_hash(self)).id
      MiniORM::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{MiniORM::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    true
  end

  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  module ClassMethods
    def create(attrs)
      attrs = MiniORM::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| MiniORM::Utility.sql_strings(attrs[key]) }

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(id, updates)

      updates = MiniORM::Utility.convert_keys(updates)
      updates.delete "id"
      updates_array = updates.map { |key, value| "#{key}=#{MiniORM::Utility.sql_strings(value)}" }

      connection.execute <<-SQL
        UPDATE #{table}
        SET #{updates_array * ","}
        WHERE id = #{id};
      SQL

      true
    end

  end
end