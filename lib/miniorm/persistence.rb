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

  def update_attributes(updates)
    self.class.update(self.id, updates)
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

    def update(ids, updates)
      if ids.count >= 2 && ids.count === updates.count && ids.is_a?(Array) && updates.is_a?(Array)
        updates_array = []
        updates.each_with_index do |update_array_item, index| 
          converted_keys = MiniORM::Utility.convert_keys(update_array_item)
          updates_array << converted_keys.map { |key, value| "#{key}=#{MiniORM::Utility.sql_strings(value)}" }.unshift(ids[index])
        end
      else
        updates = MiniORM::Utility.convert_keys(updates)
        updates.delete "id"
        updates_array = updates.map { |key, value| "#{key}=#{MiniORM::Utility.sql_strings(value)}" }
      end

      if ids.count >= 2
        set_where_sql_strings = []
        updates_array.each do |convert_keys|
          next if convert_keys[0].class != Integer
          where_statement = "WHERE id = #{convert_keys.shift(1)[0].to_s}"
          connection.execute <<-SQL
            UPDATE #{table}
            SET #{convert_keys * ","} #{where_statement};
          SQL
        end
      else
        
        if ids.class == Fixnum
          where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
          where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
          where_clause = ";"
        end

        connection.execute <<-SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL
      end

      true
    end

    def update_all(updates)
      update(nil, updates)
    end

  end
end