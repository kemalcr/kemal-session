require "../engine"

module Kemal
  class Session
    class FileEngine < Engine
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

            def delete_{{name.id}}(k : String)
              if @{{name.id}}s[k]?
                @{{name.id}}s.delete(k)
              end
            end
          {% end %}

          def initialize
            {% for name, type in vars %}
              @{{name.id}}s = Hash(String, {{type}}).new
            {% end %}
          end
        end

        define_storage({
          int:    Int32,
          bigint: Int64,
          string: String,
          float:  Float64,
          bool:   Bool,
          object: Session::StorableObject::StorableObjectContainer,
        })
      end

      @cache : StorageInstance
      @cached_session_id : String
      @cached_session_read_time : Time

      def initialize(options : Hash(Symbol, String))
        # @TODO make options optional (default value for sessions_dir = ./sessions/, maybe add format option (json, yaml...))
        raise ArgumentError.new("FileEngine: Mandatory option sessions_dir not set") unless options.has_key? :sessions_dir
        raise ArgumentError.new("FileEngine: Cannot write to directory #{options[:sessions_dir]}") unless File.directory?(options[:sessions_dir]) && File.writable?(options[:sessions_dir])
        @sessions_dir = uninitialized String
        @sessions_dir = options[:sessions_dir]
        @cache = StorageInstance.new
        @cached_session_read_time = Time.utc_now
        @cached_session_id = ""
      end

      def run_gc
        each_session do |session|
          full_path = session_filename(session.id)
          age = Time.utc_now - File.info(full_path).modification_time # mtime is always saved in utc
          session.destroy if age.total_seconds > Session.config.timeout.total_seconds
        end
      end

      def clear_cache
        @cache = StorageInstance.new
        @cached_session_id = ""
      end

      def load_into_cache(session_id : String) : StorageInstance
        @cached_session_id = session_id
        return @cache = read_or_create_storage_instance(session_id)
      end

      def is_in_cache?(session_id : String) : Bool
        if (@cached_session_read_time.to_unix / 60) < (Time.utc_now.to_unix / 60)
          @cached_session_read_time = Time.utc_now
          begin
            File.utime(Time.now, Time.now, session_filename(session_id))
          rescue ex
            puts "Kemal-session cannot update time of a sesssion file. This may not be possible on your current file system"
          end
        end
        return session_id == @cached_session_id
      end

      def save_cache
        File.write(session_filename(@cached_session_id), @cache.to_json)
      end

      def read_or_create_storage_instance(session_id : String) : StorageInstance
        if session_exists?(session_id)
          f = session_filename(session_id)
          @cached_session_read_time = File.info(f).modification_time
          json = File.read(f)
          if json && json.size > 0
            return StorageInstance.from_json(json)
          end
        end
        instance = StorageInstance.new
        @cached_session_read_time = Time.utc_now
        File.write(session_filename(session_id), instance.to_json)
        return instance
      end

      def session_exists?(session_id : String) : Bool
        File.file?(session_filename(session_id))
      end

      def create_session(session_id : String)
        read_or_create_storage_instance(session_id)
      end

      def get_session(session_id : String)
        return Session.new(session_id) if session_exists?(session_id)
        nil
      end

      def destroy_session(session_id : String)
        if session_exists?(session_id)
          File.delete(session_filename(session_id))
        end
      end

      def destroy_all_sessions
        each_session do |session|
          session.destroy
        end
      end

      def all_sessions
        array = [] of Session

        each_session do |session|
          array << session
        end

        array
      end

      def each_session
        Dir.each_child(@sessions_dir) do |f|
          full_path = File.join(@sessions_dir, f)
          if session_file?(f)
            yield Session.new(File.basename(f, ".json"))
          end
        end
      end

      def session_filename(session_id : String)
        File.join(@sessions_dir, session_id + ".json")
      end

      # Note, this is only checking if it's _probably_ a session file.
      # tldr, don't store json in the session folder or it'll get removed
      # eventually
      def session_file?(f : String)
        File.exists?(File.join(@sessions_dir, f)) && f[-5..-1] == ".json"
      end

      # Delegating int(k,v), int?(k) etc. from Engine to StorageInstance
      macro define_delegators(vars)
        {% for name, type in vars %}

          def {{name.id}}(session_id : String, k : String) : {{type}}
            load_into_cache(session_id) unless is_in_cache?(session_id)
            return @cache.{{name.id}}(k)
          end

          def {{name.id}}?(session_id : String, k : String) : {{type}}?
            load_into_cache(session_id) unless is_in_cache?(session_id)
            return @cache.{{name.id}}?(k)
          end

          def {{name.id}}(session_id : String, k : String, v : {{type}})
            load_into_cache(session_id) unless is_in_cache?(session_id)
            @cache.{{name.id}}(k, v)
            save_cache
          end

          def {{name.id}}s(session_id : String) : Hash(String, {{type}})
            load_into_cache(session_id) unless is_in_cache?(session_id)
            return @cache.{{name.id}}s
          end

          def delete_{{name.id}}(session_id : String, k : String)
            load_into_cache(session_id) unless is_in_cache?(session_id)
            @cache.delete_{{name.id}}(k)
            save_cache
          end
        {% end %}
      end

      define_delegators({
        int:    Int32,
        bigint: Int64,
        string: String,
        float:  Float64,
        bool:   Bool,
        object: Session::StorableObject::StorableObjectContainer,
      })
    end
  end
end
