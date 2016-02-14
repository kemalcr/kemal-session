require "json"
require "../engine"

class Session
  class FileSystemEngine < Engine
    class StorageInstance
      macro define_storage(vars)
        JSON.mapping({
          {% for name, type in vars %}
               {{name.id}}s: Hash(String, {{type}}),
          {% end %}
        })

        {% for name, type in vars %}
          @{{name.id}}s = Hash(String, {{type}}).new
          getter {{name.id}}s

          def {{name.id}}(k : String) : {{type}}
            return @{{name.id}}s[k]
          end

          def {{name.id}}?(k : String) : {{type}}?
            return @{{name.id}}s[k]?
          end

          def {{name.id}}(k : String, v : {{type}})
            @{{name.id}}s[k] = v
          end
        {% end %}

        def initialize
          {% for name, type in vars %}
            @{{name.id}}s = Hash(String, {{type}}).new
          {% end %}
        end
      end

      define_storage({int: Int32, string: String, float: Float64, bool: Bool})
    end

    def initialize(options : Hash(Symbol, String))
      raise ArgumentError.new("FileSystemEngine: Mandatory option sessions_dir not set") unless options.has_key? :sessions_dir
      raise ArgumentError.new("FileSystemEngine: Cannot write to directory #{options[:sessions_dir]}") unless File.directory?(options[:sessions_dir]) && File.writable?(options[:sessions_dir])
      @sessions_dir = options[:sessions_dir]
    end

    def run_gc
      Dir.foreach(@sessions_dir) do |f|
        full_path = @sessions_dir + f
        if File.file? full_path
          age = Time.utc_now - File.stat(full_path).mtime # mtime is always saved in utc
          File.delete full_path if age.total_seconds > Session.config.timeout.total_seconds
        end
      end
    end

    def read_or_create_storage_instance(session_id : String) : StorageInstance
      if File.file? @sessions_dir + session_id + ".json"
        return StorageInstance.from_json(File.read(@sessions_dir + session_id + ".json"))
      else
        instance = StorageInstance.new
        File.write(@sessions_dir + session_id + ".json", instance.to_json)
        return instance
      end
    end

    macro define_delegators(vars)
      {% for name, type in vars %}

        def {{name.id}}(session_id : String, k : String) : {{type}}
          storage_instance = read_or_create_storage_instance(session_id)
          return storage_instance.{{name.id}}(k)
        end    

        def {{name.id}}?(session_id : String, k : String) : {{type}}?
          storage_instance = read_or_create_storage_instance(session_id)
          return storage_instance.{{name.id}}?(k)
        end

        def {{name.id}}(session_id : String, k : String, v : {{type}})
          storage_instance = read_or_create_storage_instance(session_id)
          storage_instance.{{name.id}}(k, v)
          File.write(@sessions_dir + session_id + ".json", storage_instance.to_json)
        end

        def {{name.id}}s(session_id : String) : Hash(String, {{type}})
          storage_instance = read_or_create_storage_instance(session_id)
          return storage_instance.{{name.id}}s
        end
      {% end %}
    end

    define_delegators({int: Int32, string: String, float: Float64, bool: Bool})
  end
end
