require "crypto/md5"
require "json"

class Session

  @id : String

  def initialize(@id : String)
  end

  def self.start(context) : Session
    instance = new(id_from_context(context) || generate_id)
    instance.update_context(context)
    return instance
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
