require "json"

class Session
  macro abstract_engine(vars)
    abstract class Engine

      abstract def run_gc
      abstract def all_sessions : Array(Session)
      abstract def create_session(session_id : String)
      abstract def each_session(&block : Session -> _)
      abstract def get_session(session_id : String) : Session?
      abstract def destroy_session(session_id : String)
      abstract def destroy_all_sessions

      {% for name, type in vars %}

        {% if name != "object" %}
          {% t = type %}
        {% else %}
          {% t = "Session::StorableObject::StorableObjectContainer" %}
        {% end %}

        abstract def {{name.id}}(session_id : String, k : String) : {{t.id}}
        abstract def {{name.id}}?(session_id : String, k : String) : {{t.id}}?
        abstract def {{name.id}}s(session_id : String) : Hash(String, {{t.id}})
        abstract def {{name.id}}(session_id : String, k : String, v : {{t.id}})

      {% end %}

    end

    # generate delegators for each type (Session -> Engine)
    # for base types:
    {% for name, type in vars %}

      def {{name.id}}(k : String) : {{type}}
        {% if name == "object" %}
          container = Session.config.engine.{{name.id}}(@id, k)
          container.object
        {% else %}
          Session.config.engine.{{name.id}}(@id, k)
        {% end %}
      end

      def {{name.id}}?(k : String) : {{type}}?
        {% if name == "object" %}
          container = Session.config.engine.{{name.id}}?(@id, k)
          return nil if container.nil?
          container.object
        {% else %}
          Session.config.engine.{{name.id}}?(@id, k)
        {% end %}
      end

      def {{name.id}}s : Hash(String, {{type}})
        {% if name == "object" %}
          Session.config.engine.{{name.id}}s(@id).each_with_object({} of String => {{type}}) do |h, obj|
            obj[h[0]] = h[1].object
          end
        {% else %}
          Session.config.engine.{{name.id}}s(@id)
        {% end %}
      end

      def {{name.id}}( k : String, v : {{type}})
        {% if name == "object" %}
          c = Session::StorableObject::StorableObjectContainer.new(v)
          Session.config.engine.{{name.id}}(@id, k, c)
        {% else %}
          Session.config.engine.{{name.id}}(@id, k, v)
        {% end %}
      end

      def delete_{{name.id}}( k : String)
        Session.config.engine.delete_{{name.id}}(@id, k)
      end

    {% end %}
  end

  abstract_engine({
    int: Int32,
    bigint: Int64,
    string: String,
    float: Float64,
    bool: Bool,
    object: Session::StorableObject::StorableObjects,
  })
  GC.new
end
