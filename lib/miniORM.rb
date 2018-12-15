module MiniORM
  # If using pg, a connection_string must be passed.
  ## As a String
  ## MiniORM.connect_to("dbname=test port=5432", :pg)
  # Docs: https://deveiate.org/code/pg/PG/Connection.html#method-c-new

  # If using sqlite3, the connection_string must be the local filepath.
  # MiniORM.connect_to("db/test.sqlite", :sqlite3)
  def self.connect_to(connection_string, type)
    @database_connection_string = connection_string
    @database_type = type
  end

  def self.database_connection_string
    @database_connection_string
  end

  def self.database_type
    @database_type
  end
end