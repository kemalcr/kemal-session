require "kemal"
require "kemal-session"

get "/rand" do |env|
  session = Session.start(env)
  if session.int.has_key? "random_number"
    env.response.print "The last random number was #{session.int["random_number"]}. "
  else
    env.response.print "This is the first random number. "
  end
  random_number = rand(500)
  env.response.print "Setting the random number to #{random_number}"
  session.int["random_number"] = random_number
  session.save
end

get "/set" do |env|
  session = Session.start(env)
  session.string[env.params["key"].to_s] = env.params["value"].to_s
  session.save
end

get "/get" do |env|
  session = Session.start(env)
  if session.string.has_key? env.params["key"].to_s
    "The value of #{env.params["key"]} is #{session.string[env.params["key"].to_s]}"
  else
    "There is no value for this key."
  end
end

get "/view" do |env|
  session = Session.start(env)
  env.response.content_type = "application/json"
  session.to_json
end
