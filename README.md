# kemal-session

[![Build Status](https://travis-ci.org/kemalcr/kemal-session.svg?branch=master)](https://travis-ci.org/kemalcr/kemal-session)

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

### Available Types

The session can save many different types but the method names differ from the type.

| Type | Access Method |
|------|---------------|
| Int32 | `session.int` |
| Int64 | `session.bigint` |
| String | `session.string` |
| Float64 | `session.float` |
| Bool    | `session.bool` |
| StorableObject  | `session.object` |


You can also access the underyling hash directly by appending ``s`` to the name: ``session.ints``. This way you can use hash functions like
```crystal
session.ints.each do |k, v|
  puts "#{k} => #{v}"
end
```

**BUT:** This should only be used for reading and analyzing values, **never for changing them**. Because otherwise the session won't automatically save the changes and you may produce really weird bugs...

#### StorableObject

`kemal-session` has the ability to save objects to session storage. By saving objects to session storage, this opens up the ability to have more advanced data types that aren't supported by the base types (Int32, Int64, Float64, String, Bool).
Any object that you want to save to session storage needs to include the `Session::StorableObject` module. The class must respond to `to_json` and `from_json`. **NOTE** The module must be included after the definition of `to_json` and `from_json`.
Otherwise the compiler will not know that those methods have been defined on the class.
Here's an example implementation:

```crystal
class UserStorableObject
  JSON.mapping({
    id: Int32,
    name: String
  })
  include Session::StorableObject

  def initialize(@id : Int32, @name : String); end
end
```

Once a `StorableObject` has been defined, you can save that in session storage just like the base types. Here's an example using
the `UserStorableObject` implementation:

```crystal
require "kemal"
require "kemal-session"

get "/set" do |env|
  user = UserStorableObject.new(123, "charlie")
  env.session.object("user", user)
end

get "/get" do |env|
  user = env.session.object("user").as(UserStorableObject)
  "The user stored in session is #{user.name}"
end
```

Serialization is up to you. You can define how you want that to happen so long as the resulting type is a String. If you need recommendations
or advice, check with the underlying session storage implementation.

### Configuration

The Session can be configured in the same way as Kemal itself:
```crystal
Session.config do |config|
  config.cookie_name = "session_id"
  config.secret = "some_secret"
  config.gc_interval = 2.minutes # 2 minutes
end
```
or
```crystal
Session.config.cookie_name = "session_id"
Session.config.secret = "some_secret"
Session.config.gc_interval = 2.minutes # 2 minutes
```

| Option  | explanation | default |
|---|---|---|
| timeout | How long is the session valid after last user interaction?  | ```Time::Span.new(1, 0, 0)``` (1 hour)  |
| cookie_name | Name of the cookie that holds the session_id on the client | ```"kemal_sessid"``` |
| engine | How are the sessions saved on the server? (see section below) | ```Session::MemoryEngine.new``` |
| gc_interval | In which interval should the garbage collector find and delete expired sessions from the server?  | ```Time::Span.new(0, 4, 0)``` (4 minutes)  |
| secret | Used to sign the session ids before theyre saved in the cookie. *Strongly* encouraged to [create your own secret](#creating-a-new-secret) | ```""``` |
| secure | The cookie used for session management should only be transmitted over encrypted connections. | ```false``` |

#### Setting the Engine
The standard engine is the MemoryEngine

The engine you use has a huge impact on performance and can enable you to share sessions between different servers, make them available to any other application or whatever you can imagine. So the choice of engine is very important.

```crystal
Session.config.engine = Session::FileEngine.new({sessions_dir: "/var/foobar/sessions/"})
```
You can also write your own engine if you like. Take a look at the [wiki page](https://github.com/kemalcr/kemal-session/wiki/Creating-your-own-engine). If you think it might also be helpful for others just let me know about it and I will include it in a list of known engines or something.

#### Creating a new `secret`

```bash
crystal eval 'require "secure_random"; puts SecureRandom.hex(64)'
```

Once this has been generated, it's very important that you keep this in a safe
place. Environment variables tend to be a good place for that. If the
`secret` is lost all of the sessions will get reset.

### Logout and managing sessions
If you want to log a user out, simply call `destroy` on the session object:
```crystal
get "/logout" do |env|
  env.session.destroy
  "You have been logged out."
end
```
It is also possible to manage other users' sessions if you want to build an administrator's interface, for example:
- `Session.get(session_id)` returns the session object identified by the given id
- `Session.each { |session| … }` executes the given block on every session
- `Session.all` returns an array containing all sessions
- `Session.destroy(session_id)` destroys the session identified by the given id (logs the user out)
- `Session.destroy_all` destroys all sessions (logs everyone out including you)

**You should be very careful with those, though.** These functions enable you to access and modify all information that is stored in all sessions, also in those that do not belong to the current user. So take extra care of security when using them.
Additionally, depending on the engine used and on how many active sessions there are, `Session.all` and `Session.each` might be memory intensive as they have to load all the sessions into memory at once, in the worst case. It is best to check/ask how your engine handles that when in doubt.

## Features already implemented

- Storing of Int32, String, Float64 and Bool values
- Garbage collector that removes expired sessions from the server
- Memory engine
- File engine
- Manage sessions: Session.all, Session.remove(id), Session.get(id)

## Compatible Engines
- [kemal-session-redis](https://github.com/neovintage/kemal-session-redis): Redis based session storage engine.

### Thanks

Special thanks to [Thyra](https://github.com/Thyra) for initial efforts.

