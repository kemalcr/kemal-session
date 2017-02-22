require "../engine"

class Session
  class MemoryEngine < Engine
    class StorageInstance
      macro define_storage(vars)
        getter! id : String
        property! last_access_at : Int64

        JSON.mapping({
          {% for name, type in vars %}
            {{name.id}}s: Hash(String, {{type}}),
          {% end %}
          last_access_at: Int64,
          id: String,
        })

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

      define_storage({
        int: Int32,
        bigint: Int64,
        string: String,
        float: Float64,
        bool: Bool,
        object: Session::StorableObject::StorableObjects
      })
    end

    @store : Hash(String, String)

    def initialize
      @store = {} of String => String
    end

    def run_gc
      before = (Time.now - Session.config.timeout.as(Time::Span)).epoch_ms
      @store.delete_if do |id, entry|
        last_access_at = Int64.from_json(entry, root: "last_access_at")
        last_access_at < before
      end
      sleep Session.config.gc_interval
    end

    def all_sessions
      @store.each_with_object([] of Session) do |vals, arr|
        arr << Session.new(vals.first)
      end
    end

    def create_session(session_id : String)
      @store[session_id] = StorageInstance.new(session_id).to_json
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

        def {{name.id}}(session_id : String, k : String) : {{type}}
          storage_instance = StorageInstance.from_json(@store[session_id])
          return storage_instance.{{name.id}}(k)
        end

        def {{name.id}}?(session_id : String, k : String) : {{type}}?
          return nil unless @store[session_id]?
          storage_instance = StorageInstance.from_json(@store[session_id])
          return storage_instance.{{name.id}}?(k)
        end

        def {{name.id}}(session_id : String, k : String, v : {{type}})
          if @store[session_id]?
            storage_instance = StorageInstance.from_json(@store[session_id])
          else
            storage_instance = StorageInstance.new(session_id)
          end
          storage_instance.{{name.id}}(k, v)
          @store[session_id] = storage_instance.to_json
        end

        def {{name.id}}s(session_id : String) : Hash(String, {{type}})
          return {} of String => {{ type }} unless @store[session_id]?
          storage_instance = StorageInstance.from_json(@store[session_id])
          return storage_instance.{{name.id}}s
        end
      {% end %}
    end

    define_delegators({
      int: Int32,
      bigint: Int64,
      string: String,
      float: Float64,
      bool: Bool,
      object: Session::StorableObject::StorableObjects,
    })
  end
end
