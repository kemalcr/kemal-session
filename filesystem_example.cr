require "kemal"
require "./src/kemal-session"

Session.config do |config|
  puts config.engine
  config.engine = Session::FileSystemEngine.new({sessions_dir: "./sessions/"})
  puts config.engine
end

get "/" do |env|
  session = Session.start(env)
  session.int("12", 15)
  session.int?("43")
  session.ints.each do |k, v|
    puts "#{k} => #{v}"
  end
end
