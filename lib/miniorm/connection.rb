 require 'sqlite3'
 require 'pg'
 
 module Connection
   def connection
    binding.pry
    if MiniORM.database_type === :sqlite3
      @connection ||= SQLite3::Database.new(MiniORM.database_connection_string)
    elsif MiniORM.database_type === :pg
      @connection ||= PG::Connection.new(MiniORM.database_connection_string)
    else
      raise "Database type not found."
    end
   end
 end