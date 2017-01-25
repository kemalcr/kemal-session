class Session
  STORABLE_TYPES = [] of Nil

  module StorableObject
    macro included
      {% Session::STORABLE_TYPES << @type %}

      macro finished
        {% if !@type.class.overrides?(Object, "from_json") %}
          {{ raise("StorableObject #{@type} needs to define `from_json`") }}
        {% end %}

        {% if !@type.overrides?(Object, "to_json") %}
          {{ raise("StorableObject #{@type} needs to define `to_json`") }}
        {% end %}
      end
    end

    macro finished
      alias StorableObjects = Union({{ *Session::STORABLE_TYPES }})
    end
  end
end
