class Session
  macro abstract_engine(vars)
    abstract class Engine

      abstract def run_gc
      abstract def all : Array(Session)
      abstract def build(session_id : String)
      abstract def each(&block : Session -> _)
      abstract def get(session_id : String) : Session?
      abstract def destroy(session_id : String)
      abstract def destroy_all

      {% for name, type in vars %}

        abstract def {{name.id}}(session_id : String, k : String) : {{type}}
        abstract def {{name.id}}?(session_id : String, k : String) : {{type}}?
        abstract def {{name.id}}s(session_id : String) : Hash(String, {{type}})
        abstract def {{name.id}}(session_id : String, k : String, v : {{type}})

      {% end %}

    end

    # generate delegators for each type (Session -> Engine)
    {% for name, type in vars %}

      def {{name.id}}(k : String) : {{type}}?
        Session.config.engine.{{name.id}}(@id, k)
      end

      def {{name.id}}?(k : String) : {{type}}?
        Session.config.engine.{{name.id}}?(@id, k)
      end

      def {{name.id}}s : Hash(String, {{type}})
        Session.config.engine.{{name.id}}s(@id)
      end

      def {{name.id}}( k : String, v : {{type}})
        Session.config.engine.{{name.id}}(@id, k, v)
      end

    {% end %}
  end

  abstract_engine({int: Int32, string: String, float: Float64, bool: Bool})
  GC.new
end
