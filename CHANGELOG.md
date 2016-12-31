# 0.6.0 (01-01-2017)

This is a major release which adds `StoreableObject`. Big thanks to @neovintage :+1

### StorableObject

`kemal-session` has the ability to save objects to session storage. By saving objects to session storage, this opens up the ability to have more advanced data types that aren't supported by the base types (Int32, Float64, String, Bool). 
Any object that you want to save to session storage needs to be a subclass of `Session::StorableObject`. 
The subclass needs to define two different methods. First, a class method to deserialize the object from a String, called `unserialize`. The 
second method, is an instance method called `serialize`. `serialize` will take the object and turn it into a String for the session storage engine to 
handle. Here's an example implementation:

```crystal
class UserStorableObject < Session::StorableObject
  property id, name

  def initialize(@id : Int32, @name : String); end

  def serialize
    return "#{@id};#{@name}"
  end

  def self.unserialize(value : String)
    parts = value.split(";")
    return self.new(parts[0].to_i, parts[1])
  end
end
```

Once a `StorableObject` subclass has been defined, you can save that in session storage just like the base types. Here's an example using 
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

# 0.5.0 (22-12-2016)

This is a major release which adds Session administration capabilities (check #7 for more info). Big thanks to @neovintage and @Thyra 🎉 

- `#get` to get a session with the given `session_id`.
- `#all` to get every saved sessions.
- `#each` to iterate through all sessions.
- `.destroy` and `#destroy` to remove a session.
- `#destroy_all` to remove all sessions.

# 0.4.0 (03-12-2016)

- Sign cookies with `secret`. It's required to have a `secret`. (thanks @neovintage)
- Fix multiple GC initilization.