
require 'sqlite3'
require 'pry'
module Selection
  def find(*ids)
    begin
      ids = ids.flatten
      raise ArgumentError, 'Argument is not numeric' unless validate_number(ids)
      if ids.length == 1
        find_one(ids.first)
      else
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          WHERE id IN (#{ids.join(",")});
        SQL

        rows_to_array(rows)
      end
    rescue ArgumentError
      return "#{ids} contains an invalid input."
    end
  end

  def find_each(start=0,batch=100)
    begin
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} 
        FROM #{table}
        ORDER BY id ASC
        LIMIT #{batch} OFFSET #{start};
      SQL

      rows_to_array(rows)
    end
  end

  def find_in_batches(start=0,batch=100)
    begin
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} 
          FROM #{table}
          ORDER BY id ASC
          LIMIT #{batch} OFFSET #{start};
        SQL
        if block_given?
          yield rows_to_array(rows)
        else
          rows_to_array(rows)
        end
      increment = 1
      while (increment * batch) < count
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} 
          FROM #{table}
          WHERE id >= #{increment*batch}
          ORDER BY id ASC
          LIMIT #{batch};
        SQL
        if block_given?
          yield rows_to_array(rows)
        else
          rows_to_array(rows)
        end
        increment = increment + 1
      end
    end
  end

  def find_one(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    begin
      raise ArgumentError, 'Argument value does not match attribute type' unless validate_find_by(attribute, value)
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{attribute} = #{MiniORM::Utility.sql_strings(value)};
      SQL

      rows_to_array(rows)
    rescue ArgumentError
      return "#{value} is an invalid input."
    end
  end

  def take(num=1)
    begin
      raise RangeError if num > count
      if num > 1
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          ORDER BY random()
          LIMIT #{num};
        SQL

        rows_to_array(rows)
      else
        take_one
      end
    rescue RangeError
      return "Argument exceeds range of rows. Request (#{num}) is greater than number of rows (#{count})."
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end
  
  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def method_missing(m, *args)
    begin
      if m.to_s.include?("find_by_")
        attribute = m.match(/find_by_?(.*)/)[1]
        if schema.keys.include?(attribute)
          return find_by(attribute, args[0])
        else
          raise NoMethodError
        end
      elsif m.to_s.include?("update_")
        attribute = m.match(/update_?(.*)/)[1]
        if schema.keys.include?(attribute)
          return update(args[0], {attribute => args[1]})
        else
          raise NoMethodError
        end
      else
        raise NoMethodError
      end
    rescue NoMethodError
      return "There's no method called #{m} here -- please try again."  
    end
  end  


  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
    case args.first
    when String
      expression = args.first
    when Hash
      expression_hash = MiniORM::Utility.convert_keys(args.first)
      expression = expression_hash.map {|key, value| "#{key}=#{MiniORM::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end
  
  def order(*args)
    if args.count > 1
      order = {}
      args.each do |arg|
        case arg
        when Hash
          order = order.merge(arg)
        when Symbol
          order[arg] = :asc
        when String
          str = arg.split(" ")
          order[str[0].to_sym] = str[1].downcase.to_sym
        end
      end
    elsif !args[0].is_a?(Symbol)
      if args[0].include?(",")
        order = {}
        args = args[0].split(",")
        args.each do |arg|
          arg = arg.gsub(/(^\s)|[:]/, "")
          str = arg.split(" ")
          order[str[0].to_sym] = str[1].downcase.to_sym
        end
      end
    else
      order = args.first.to_s
    end
    unless order.is_a?(String)
      # gsub is a two step conversion, first removing {}:= and whitespace
      # then it swaps > with empty whitespace
      # i.e. {:name=>:asc, :phone_number=>:desc}
      # to:  "name asc, phone_number desc"
      order = order.to_s.gsub(/(^\s|{)|[:=]|(}$)/, "").gsub(/[>]/, " ")
    end
    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL

    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        args = args.first.flatten.map &:to_s
        joins = []
        args.each_with_index do |arg, i|
          if i === 0
            joins << "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"
          else
            joins << "INNER JOIN #{args[i]} ON #{args[i]}.#{args[i-1]}_id = #{args[i-1]}.id"
          end
        end
        joins = joins.join(" ")
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{joins}
        SQL
      end
    end

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = MiniORM::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end

  def validate_number(*num)
    num.any? { |value| !value.is_a?(Numeric || Integer) }
  end

  def validate_find_by(attribute, value)
    begin
      return false unless schema.keys.include?(attribute.to_s)
      if schema["#{attribute}"].include?("VARCHAR")
        varchar_count = schema["#{attribute}"].match(/[0-9]+/)[0].to_i
        return false if value.length > varchar_count || value.length == 0
        true
      elsif schema["#{attribute}"] = "INTEGER"
        validate_number(value)
      else
        false
      end
    end
  end

end