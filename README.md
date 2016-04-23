# kemal-session

This project wants to be a session plugin for [Kemal](https://github.com/sdogruyol/kemal) when it grows up. It is still in alpha stage but it works! ;-)

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  kemal-session:
    github: Thyra/kemal-session
    branch: master
```


## Usage

### Basic Usage
Create a folder ```sessions``` in the same directory that your webserver is running in and make sure the webserver process has write privileges to it.
```crystal
require "kemal"
require "kemal-session"

get "/set" do |env|
  env.session.int("number", rand(100)) # set the value of "number"
  "Random number set."
end

get "/get" do |env|
  num  = env.session.int("number") # get the value of "number"
  env.session.int?("hello") # get value or nil, like []?
  "Value of random number is #{num}."
end

Kemal.run
```
The session can save Int32, String, Float64 and Bool values. Use ```session.int```, ```session.string```, ```session.float``` and ```session.bool``` for that.

Another example
```crystal
require "kemal"
require "kemal-session"

get "/rand" do |env|
  if env.session.int? "random_number"
    env.response.print "The last random number was #{env.session.int("random_number")}. "
  else
    env.response.print "This is the first random number. "
  end
  random_number = rand(500)
  env.session.int("random_number", random_number)
  env.response.print "Setting the random number to #{random_number}"
end

get "/set" do |env|
  env.session.string(env.params.query["key"].to_s, env.params.query["value"].to_s)
  "Setting <i>#{env.params.query["key"]}</i> to <i>#{env.params.query["value"]}</i>"
end

get "/get" do |env|
  if env.session.string? env.params.query["key"].to_s
    "The value of #{env.params.query["key"]} is #{env.session.string(env.params.query["key"].to_s)}"
  else
    "There is no value for this key."
  end
end

Kemal.run
```
Open ```/set?key=foo&value=bar``` to set the value of *foo* to *bar* in your session. Then open ```/get?key=foo``` to retrieve it.

You can also access the underyling hash directly by appending ``s`` to the name: ``session.ints``. This way you can use hash functions like
```crystal
session.ints.each do |k, v|
  puts "#{k} => #{v}"
end
```
**BUT:** This should only be used for reading and analyzing values, **never for changing them**. Because otherwise the session won't automatically save the changes and you may produce really weird bugs... 

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
| engine | How are the sessions saved on the server? (see section below) | ```Session::FileSystemEngine.new({sessions_dir: "./sessions/"})``` |
| gc_interval | In which interval should the garbage collector find and delete expired sessions from the server?  | ```Time::Span.new(0, 4, 0)``` (4 minutes)  |

#### Setting the Engine
The Engine takes care of actually saving the sessions on the server. The standard engine is the FileSystemEngine which creates a json file for each session in a certain folder on the file system. Theoretically there are innumerable possible engines; any way of storing and retrieving values could be used:
* Storing the values in a database (MySQL, SQLite, MongoDB etc.)
* Storing the values in RAM (e.g. like Redis)
* Saving and retreiving the values from a remote server via an API
* Printing on paper, rescanning and running an OCR on it.
 
The engine you use has a huge impact on performance and can enable you to share sessions between different servers, make them available to any other application or whatever you can imagine. So the choice of engine is very important. Luckily for you, there is only one engine available right now ;-): The FileSystemEngine. It is set by default to store all the session in a folder called sessions in the directory the server is running in. If you want to save them someplace else, just use this:

```crystal
Session.config.engine = Session::FileSystemEngine.new({sessions_dir: "/var/foobar/sessions/"})
```
You can also write your own engine if you like. Take a look at the [wiki page](https://github.com/Thyra/kemal-session/wiki/Creating-your-own-engine). If you think it might also be helpful for others just let me know about it and I will include it in a list of known engines or something.

### Features already implemented
- storing of Int32, String, Float64 and Bool values
- a garbage collector that removes expired sessions from the server
- a filesystem engine (saves sessions on the file system)

### Features in development
- storing of more data types, including arrays and possibly hashes
- engines for memory (sessions are stored in process memory), mysql and postregsql (sessions are stored in database)
- secure session id against brute force attacks by binding it to ip adress and user agent
- Manage sessions: Session.all, Session.remove(id), Session.get(id)...
