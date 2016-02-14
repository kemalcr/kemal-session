require "../engine"

class Session
  class DummyEngine < Engine

    macro define_storage(vars)

      {% for name, type in vars %}

        def {{name.id}}(session_id : String, k : String) : {{type}}
          puts "Session #{session_id}: Getting value #{k}"
        end    

        def {{name.id}}?(session_id : String, k : String) : {{type}}?
          puts "Session #{session_id}: Maybe getting value of #{k}"
        end

        def {{name.id}}(session_id : String, k : String, v : {{type}})
          puts "Session #{session_id}: Setting value of #{k} to #{v}"
        end

        def {{name.id}}s(session_id : String) : Hash(String, {{type}})
          puts "Session #{session_id}: Getting Hash of {{type}}"
          return {} of String => {{type}}
        end
      {% end %}
    end

    define_storage({int: Int32, string: String, float: Float64, bool: Bool})

    def initialize(options : Hash(Symbol, String))
      puts "Initalizing DummyEngine with these options: #{options}"
    end

    def run_gc
      puts "Running gc"
    end

  end
end
