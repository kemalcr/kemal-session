# kemal-session

Session support for [Kemal](https://github.com/sdogruyol/kemal) :rocket:

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  kemal-session:
    github: kemalcr/kemal-session
    branch: master
```

## Usage

### Basic Usage

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
  config.secret = "some_secret"
  config.gc_interval = Time::Span.new(0, 1, 0) # 1 minutes
end
```
or
```crystal
Session.config.cookie_name = "session_id"
Session.config.secret = "some_secret"
Session.config.gc_interval = Time::Span.new(0, 1, 0) # 1 minutes
```

| Option  | explanation | default |
|---|---|---|
| timeout | How long is the session valid after last user interaction?  | ```Time::Span.new(1, 0, 0)``` (1 hour)  |
| cookie_name | Name of the cookie that holds the session_id on the client | ```"kemal_sessid"``` |
| engine | How are the sessions saved on the server? (see section below) | ```Session::FileSystemEngine.new({sessions_dir: "./sessions/"})``` |
| gc_interval | In which interval should the garbage collector find and delete expired sessions from the server?  | ```Time::Span.new(0, 4, 0)``` (4 minutes)  |
| secret | Used to sign the session ids before theyre saved in the cookie. *Strongly* encouraged to [create your own secret](#creating-a-new-secret) | "" |

#### Setting the Engine
The standard engine is the MemoryEngine 
 
The engine you use has a huge impact on performance and can enable you to share sessions between different servers, make them available to any other application or whatever you can imagine. So the choice of engine is very important.

```crystal
Session.config.engine = Session::FileSystemEngine.new({sessions_dir: "/var/foobar/sessions/"})
```
You can also write your own engine if you like. Take a look at the [wiki page](https://github.com/kemalcr/kemal-session/wiki/Creating-your-own-engine). If you think it might also be helpful for others just let me know about it and I will include it in a list of known engines or something.

#### Creating a new `secret`

```bash
crystal eval 'require "secure_random"; puts SecureRandom.hex(64)'
```

Once this has been generated, it's very important that you keep this in a safe
place. Environment variables tend to be a good place for that. If the
`secret` is lost all of the sessions will get reset.

### Features already implemented
- Storing of Int32, String, Float64 and Bool values
- Garbage collector that removes expired sessions from the server
- Memory engine

### Roadmap
- More data types, including arrays and possibly hashes
- Manage sessions: Session.all, Session.remove(id), Session.get(id)

## Compatible Engines

- [kemal-session-file](https://github.com/kemalcr/kemal-session-file): File system based persistent storage session engine.

### Thanks

Special thanks to [Thyra](https://github.com/Thyra) for initial efforts.
