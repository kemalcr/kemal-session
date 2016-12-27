class Session
  abstract class StorableObject
    abstract def serialize : String
    def self.unserialize(obj : String) : self
      raise NotImplementedException.new
    end

    class NotImplementedException < Exception
      def initialize
        error_message = "StorableObject is missing unserialize definition"
        super
      end
    end
  end
end
