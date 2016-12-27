class Session
  abstract class StorableObject
    abstract def serialize : String
    def self.unserialize(obj : String) : self
      raise NotImplementedException.new("StorableObject #{self} needs to define the 'self.unserialize' method")
    end

    class NotImplementedException < Exception; end
  end
end
