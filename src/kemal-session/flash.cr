module Kemal
  class Session
    class Flash
      FLASH_PREFIX = "_flash_"

      def initialize(@session : Session)
      end

      # env.flash["notice"] = "welcome"
      def []=(key : String, value : String)
        @session.string("#{FLASH_PREFIX}#{key}", value)
      end

      # env.flash["notice"]? - returns value and marks for deletion
      def []?(key : String) : String?
        full_key = "#{FLASH_PREFIX}#{key}"
        value = @session.string?(full_key)
        @session.delete_string(full_key) if value
        value
      end

      # env.flash["notice"] - raises if not found
      def [](key : String) : String
        self[key]? || raise KeyError.new("Flash key not found: #{key}")
      end
    end
  end
end
