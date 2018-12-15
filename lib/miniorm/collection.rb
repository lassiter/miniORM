module MiniORM
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def where(arg)
      arg_key = arg.keys[0].to_s
      self.select do |obj|
        arg.values[0] == obj.instance_variable_get("@#{arg_key}").to_s
      end
    end

    def not(arg)
      arg_key = arg.keys[0].to_s
      self.select do |obj|
        arg.values[0] != obj.instance_variable_get("@#{arg_key}").to_s
      end
    end

    def take(n=1)
      if n >= 2
        self[0..(n-1)]
      else
        self.first
      end
    end

    def destroy_all
      ids = self.map(&:id)
      self.any? ? self.first.class.destroy(ids) : false
    end
  end
end