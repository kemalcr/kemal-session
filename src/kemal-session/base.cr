require "crypto/md5"
require "json"

class Session

  # @TODO Is there any way to outsource this to another file?
  macro define_storage(vars)
    JSON.mapping({
      id: String,

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
        save
      end
    {% end %}

  end

  define_storage({int: Int32, string: String, float: Float64, bool: Bool})

  def initialize(@id : String)
  end

  def self.start(context) : Session
    instance : Session
    if(id = id_from_context(context))
      instance = restore_instance(id)
    else
      instance = new(generate_id)
    end
    instance.update_context(context)
    instance.save # @TODO
    return instance
  end

  def self.restore_instance(id : String) : Session
    instance : Session
    case Session.config.engine
    when "filesystem"
      instance = e_filesystem_restore_instance(id)
    else
      raise "Session: Unknown engine: #{Session.config.engine}"
    end
    instance
  end

  # Unfortunately this finalize is not executed
  # when a get block etc finishes. Otherwise it
  # would be a nice way of avoiding session.save all the time...
  def finalize
    save
  end

  def save
    case Session.config.engine
    when "filesystem"
      e_filesystem_save
    end
  end

  # @TODO make sure the id is unique
  def self.generate_id
    raw = ""
    r = Random.new
    8.times do
      case r.rand(3)
      when 0
        raw += r.next_bool.to_s
      when 1
        raw += r.next_int.to_s
      when 2
        raw += r.next_float.to_s
      when 3
        raw += r.next_u32.to_s
      end
    end
    Crypto::MD5.hex_digest(raw)
  end
end
