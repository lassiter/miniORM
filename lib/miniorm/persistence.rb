require 'sqlite3'
require 'miniorm/schema'

module Persistence

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
end