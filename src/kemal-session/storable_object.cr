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
      {% if !Session::STORABLE_TYPES.empty? %}
        alias StorableObjects = Union({{ *Session::STORABLE_TYPES }})

        # This is a container object that allows us to define the type from
        # session storage so that we can parse everythin correctly
        #
        class StorableObjectContainer
          property type : String
          property object : Session::StorableObject::StorableObjects

          def initialize(obj : StorableObjects)
            @type = obj.class.to_s
            @object = obj
          end

          def initialize(parser : JSON::PullParser)
            c = self.class.from_json(parser)
            @type = c.type
            @object = c.object
          end

          def to_json(builder : JSON::Builder)
            builder.object do
              builder.field "type", @type
              builder.field "object" do
                @object.to_json(builder)
              end
            end
          end

          def self.from_json(parser : JSON::PullParser)
            # Parse the stuffs. Note that we're not going to parse the
            # object json for the storable object we need to know the
            # type before we do so
            #
            parser.read_begin_object
            key  = parser.read_object_key
            type = parser.read_string
            parser.read_object_key
            json = parser.read_raw
            parser.read_end_object

            {% for type in Session::STORABLE_TYPES %}
              if "{{ type }}" == type
                object = {{ type }}.from_json(json)
              end
            {% end %}

            if object.nil?
              raise JSON::ParseException.new("Couldn't parse StorableObject #{type} from #{json}", 0, 0)
            end
            return Session::StorableObject::StorableObjectContainer.new(object)
          end
        end
      {% else %}
        alias StorableObjects = Nil
        alias StorableObjectContainer = Nil
      {% end %}
    end
  end
end
