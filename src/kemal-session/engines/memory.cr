require "../engine"

class Session
  class MemoryEngine < Engine
    class StorageInstance
      macro define_storage(vars)
        getter! id : String
        property! last_access_at : Int64

        {% for name, type in vars %}
          @{{name.id}}s = Hash(String, {{type}}).new
          @last_access_at = Time.new.epoch_ms
          getter {{name.id}}s

          def {{name.id}}(k : String) : {{type}}
            @last_access_at = Time.new.epoch_ms
            return @{{name.id}}s[k]
          end

          def {{name.id}}?(k : String) : {{type}}?
            @last_access_at = Time.new.epoch_ms
            return @{{name.id}}s[k]?
          end

          def {{name.id}}(k : String, v : {{type}})
            @last_access_at = Time.new.epoch_ms
            @{{name.id}}s[k] = v
          end
        {% end %}

        def initialize(@id : String)
          {% for name, type in vars %}
            @{{name.id}}s = Hash(String, {{type}}).new
          {% end %}
        end
      end

      define_storage({int: Int32, string: String, float: Float64, bool: Bool, array: Array(SessionType)})
    end

    @store : Hash(String, StorageInstance)

    def initialize
      @store = {} of String => StorageInstance
    end

    def run_gc
      before = (Time.now - Session.config.timeout.as(Time::Span)).epoch_ms
      @store.delete_if { |id, entry| entry.last_access_at < before }
      sleep Session.config.gc_interval
    end

    def all_sessions
      @store.each_with_object([] of Session) do |vals, arr|
        arr << Session.new(vals.first)
      end
    end

    def create_session(session_id : String)
      @store[session_id] = StorageInstance.new(session_id)
    end

    def each_session
      @store.each do |key, val|
        yield Session.new(key)
      end
    end

    def get_session(session_id : String)
      return nil if !@store.has_key?(session_id)
      Session.new(session_id)
    end

    # Removes session from being tracked
    #
    def destroy_session(session_id : String)
      if @store[session_id]?
        @store.delete(session_id)
      end
    end

    def destroy_all_sessions
      @store.clear
    end

    # Delegating int(k,v), int?(k) etc. from Engine to StorageInstance
    macro define_delegators(vars)
      {% for name, type in vars %}

        def {{name.id}}(session_id : String, k : String) : {{type}}?
          return @store[session_id]?.try &.{{name.id}}(k)
        end

        def {{name.id}}?(session_id : String, k : String) : {{type}}?
          return @store[session_id]?.try &.{{name.id}}?(k)
        end

        def {{name.id}}(session_id : String, k : String, v : {{type}})
          store = @store[session_id]? || begin
            @store[session_id] = StorageInstance.new(session_id)
          end
          store.{{name.id}}(k, v)
        end

        def {{name.id}}s(session_id : String) : Hash(String, {{type}})
          return @store[session_id]?.try &.{{name.id}}s
        end
      {% end %}
    end

    define_delegators({int: Int32, string: String, float: Float64, bool: Bool, array: Array(SessionType)})
  end
end
