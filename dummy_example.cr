require "kemal"
require "./src/kemal-session"

Session.config do |config|
  puts config.engine
  config.engine = Session::DummyEngine.new({option2: "value2"})
  puts config.engine
end

get "/" do |env|
  session = Session.start(env)
  # session.bool("haa") #-> this throws an error for DummyEngine because it doesn't return Bool
  session.int?("sas")
  session.string("hu", "ha")
  session.floats
end
