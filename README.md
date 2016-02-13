# kemal-session

This project wants to be a session plugin for [Kemal](https://github.com/sdogruyol/kemal) when it grows up. Right now it is still kind of crude and I wouldn't recommend anyone using it... but **it works! ;-)**

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  kemal-session:
    github: Thyra/kemal-session
```


## Usage

### Basic Usage
Create a folder ```sessions``` in the same directory that your webserver is running in and make sure the webserver process has write privileges to it.
```crystal
require "kemal"
require "kemal-session"

get "/set" do |env|
  session = Session.start(env)
  session.int["number"] = rand(100)
  session.save
end

get "/get" do |env|
  session = Session.start(env)
  session.int["number"]
end
```
The session can save Int32, String, Float64 and Bool values. Use ```session.int```, ```session.string```, ```session.float``` and ```session.bool``` for that, they are all Hashes with String keys.
Whenever you change something in the session call session.save at the end of the block so that your changes are saved (I know this is horrible and I promise it won't stay like that).

Another example
```crystal
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
```
Open ```/set?key=foo&value=bar``` to set the value of *foo* to *bar* in your session. Then open ```/get?key=foo``` to retrieve it.

### Configuration

The Session can be configured in the same way as Kemal itself:
```crystal
Session.config do |config|
  config.cookie_name = "session_id"
  config.gc_interval = Time::Span.new(0, 1, 0)
end
```
or
```crystal
Session.config.cookie_name = "foobar"
```

| Option  | explanation | default |
|---|---|---|
| timeout | How long is the session valid after last user interaction?  | ```Time::Span.new(1, 0, 0)``` (1 hour)  |
| cookie_name | Name of the cookie that holds the session_id on the client | ```"kemal_sessid"``` |
| engine | How are the sessions saved on the server? (so far only ```filesystem``` is available) | ```"filesystem"``` |
| sessions_dir | For filesystem engine: in which directory are the sessions saved? | ```"./sessions/"``` |
| gc_interval | In which interval should the garbage collector find and delete expired sessions from the server?  | ```Time::Span.new(0, 4, 0)``` (4 minutes)  |

### Features already implemented
- storing of Int32, String, Float64 and Bool values
- a garbage collector that removes expired sessions from the server
- a filesystem engine (saves sessions on the file system)

### Features in development
- a smart way of automatic saving...
- storing of more data types, including arrays and possibly hashes
- engines for memory (sessions are stored in process memory), mysql and postregsql (sessions are stored in database)
- secure session id against brute force attacks by binding it do ip adress and user agent
