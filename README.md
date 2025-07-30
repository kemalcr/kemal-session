# kemal-session

[![Build Status](https://github.com/kemalcr/kemal-session/actions/workflows/ci.yml/badge.svg)](https://github.com/kemalcr/kemal-session/actions/workflows/ci.yml)

> 🚀 **Powerful session management for Kemal web applications**

Add secure, persistent session support to your [Kemal](https://github.com/sdogruyol/kemal) web applications with just a few lines of code! Perfect for user authentication, shopping carts, temporary data storage, and more.

## ✨ Why kemal-session?

- 🎯 **Simple & Intuitive**: Get started in minutes with a clean, easy-to-use API
- 🔒 **Secure by Default**: Built-in CSRF protection and signed session cookies
- 🏎️ **Fast & Flexible**: Multiple storage engines (Memory, File, Redis, PostgreSQL, etc.)
- 🧩 **Type-Safe**: Support for all Crystal types plus custom objects
- 🛡️ **Production Ready**: Automatic session cleanup and security best practices

## 📦 Installation

Add kemal-session to your `shard.yml`:

```yaml
dependencies:
  kemal-session:
    github: kemalcr/kemal-session
```

Then run:
```bash
shards install
```

## 🚀 Quick Start

### 1. Basic Session Usage

```crystal
require "kemal"
require "kemal-session"

# Session Configuration
Kemal::Session.config.secret = "my-secret-key"

# Store data in session
get "/login" do |env|
  env.session.string("username", "alice")
  env.session.int("user_id", 123)
  "Welcome! You're now logged in."
end

# Retrieve data from session
get "/profile" do |env|
  username = env.session.string("username")
  user_id = env.session.int("user_id")
  
  "Hello #{username}! Your ID is #{user_id}"
end

# Optional values (returns nil if not found)
get "/dashboard" do |env|
  last_visit = env.session.string?("last_visit")
  message = last_visit ? "Welcome back! Last visit: #{last_visit}" : "First time here!"
  
  env.session.string("last_visit", Time.utc.to_s)
  message
end

Kemal.run
```

### 2. Real-World Example: Shopping Cart

```crystal
require "kemal"
require "kemal-session"

# Session Configuration
Kemal::Session.config.secret = "my-secret-key"

# Add item to cart
post "/cart/add" do |env|
  product_id = env.params.body["product_id"].as(String)
  
  # Get existing cart or create new one
  cart = env.session.object?("cart") || [] of String
  cart << product_id
  
  env.session.object("cart", cart)
  "Item added to cart! Total items: #{cart.size}"
end

# View cart
get "/cart" do |env|
  cart = env.session.object?("cart") || [] of String
  
  if cart.empty?
    "Your cart is empty"
  else
    "Your cart: #{cart.join(", ")} (#{cart.size} items)"
  end
end

Kemal.run
```

## 🛡️ CSRF Protection

Protect your application from Cross-Site Request Forgery attacks with built-in CSRF middleware.

### Basic CSRF Setup

```crystal
require "kemal"
require "kemal-session"

# Session Configuration
Kemal::Session.config.secret = "my-secret-key"

# Add CSRF protection
add_handler Kemal::Session::CSRF.new

get "/form" do |env|
  csrf_token = env.session.string("csrf")
  
  <<-HTML
  <form method="POST" action="/submit">
    <input type="hidden" name="authenticity_token" value="#{csrf_token}">
    <input type="text" name="message" placeholder="Enter message">
    <button type="submit">Submit</button>
  </form>
  HTML
end

post "/submit" do |env|
  message = env.params.body["message"]
  "Message received: #{message}"
end

Kemal.run
```

### Advanced CSRF Configuration

```crystal
# Customize CSRF behavior
add_handler Kemal::Session::CSRF.new(
  header: "X-CSRF-TOKEN",                      # Custom header for AJAX requests
  allowed_methods: ["GET", "HEAD", "OPTIONS"], # Methods that skip CSRF check
  allowed_routes: ["/api/public"],             # Public routes that skip CSRF
  parameter_name: "_token",                    # Custom form field name
  error: "Invalid or missing CSRF token",      # Custom error message
  per_session: false                           # see below
)
```
If `per_session` is `false` (the default), the token is valid for one use; 
if `per_session` is `true` the token does not change during a session's lifetime.
This is useful for partial page updates with AJAX-based approaches like HTMX.

### CSRF for API Endpoints

```crystal
# Custom error handler for JSON APIs
csrf_handler = Kemal::Session::CSRF.new(
  error: ->(env : HTTP::Server::Context) {
    env.response.content_type = "application/json"
    env.response.status_code = 403
    {"error" => "CSRF token required"}.to_json
  }
)

add_handler csrf_handler
```

## 📊 Supported Data Types

Kemal Session supports all common Crystal types with intuitive method names:

| Crystal Type | Session Method | Example |
|--------------|----------------|---------|
| `Int32` | `session.int` | `env.session.int("count", 42)` |
| `Int64` | `session.bigint` | `env.session.bigint("timestamp", 1234567890_i64)` |
| `String` | `session.string` | `env.session.string("name", "Alice")` |
| `Float64` | `session.float` | `env.session.float("price", 19.99)` |
| `Bool` | `session.bool` | `env.session.bool("logged_in", true)` |
| Custom Objects | `session.object` | `env.session.object("user", user_obj)` |

### 🔍 Reading Values

```crystal
# Get values (raises if not found)
count = env.session.int("count")
name = env.session.string("username")

# Get optional values (returns nil if not found)
count = env.session.int?("count")      # returns Int32 or nil
name = env.session.string?("username") # returns String or nil

# Provide default values
count = env.session.int?("count") || 0
theme = env.session.string?("theme") || "light"
```

### 🗂️ Working with Collections

Access the underlying hash for advanced operations (read-only):

```crystal
# Iterate through all integer values
env.session.ints.each do |key, value|
  puts "#{key}: #{value}"
end

# Check what string keys exist
if env.session.strings.has_key?("username")
  puts "User is logged in"
end

# Get all session data
puts "Total sessions: #{env.session.strings.size}"
```

⚠️ **Important**: Only use hash access for reading. Never modify values directly through these hashes, as changes won't be persisted!

## 🎯 Custom Objects (StorableObject)

Store complex objects in sessions by implementing the `StorableObject` module. Perfect for user profiles, preferences, or any custom data structures.

### Creating a Storable Object

```crystal
# Define your class with JSON serialization
class User
  include JSON::Serializable
  include Kemal::Session::StorableObject  # Add this after JSON::Serializable

  property id : Int32
  property name : String
  property email : String
  property preferences : Hash(String, String)

  def initialize(@id : Int32, @name : String, @email : String)
    @preferences = {} of String => String
  end
end
```

### Using Storable Objects

```crystal
require "kemal"
require "kemal-session"

# Session Configuration
Kemal::Session.config.secret = "my-secret-key"

# Store user in session
post "/login" do |env|
  user = User.new(123, "Alice", "alice@example.com")
  user.preferences["theme"] = "dark"
  user.preferences["language"] = "en"
  
  env.session.object("current_user", user)
  "Login successful!"
end

# Retrieve user from session
get "/profile" do |env|
  user = env.session.object("current_user").as(User)
  
  <<-HTML
  <h1>Welcome, #{user.name}!</h1>
  <p>Email: #{user.email}</p>
  <p>Theme: #{user.preferences["theme"]?}</p>
  HTML
end

# Update user preferences
post "/preferences" do |env|
  user = env.session.object("current_user").as(User)
  user.preferences["theme"] = env.params.body["theme"].as(String)
  
  # Save updated user back to session
  env.session.object("current_user", user)
  "Preferences updated!"
end
```

### Complex Example: Shopping Cart with Items

```crystal
class CartItem
  include JSON::Serializable
  include Kemal::Session::StorableObject

  property id : String
  property name : String
  property price : Float64
  property quantity : Int32

  def initialize(@id : String, @name : String, @price : Float64, @quantity : Int32 = 1)
  end

  def total
    price * quantity
  end
end

class ShoppingCart
  include JSON::Serializable
  include Kemal::Session::StorableObject

  property items : Array(CartItem)

  def initialize
    @items = [] of CartItem
  end

  def add_item(item : CartItem)
    existing = items.find { |i| i.id == item.id }
    if existing
      existing.quantity += item.quantity
    else
      items << item
    end
  end

  def total
    items.sum(&.total)
  end

  def item_count
    items.sum(&.quantity)
  end
end

# Usage in routes
post "/cart/add" do |env|
  cart = env.session.object?("cart").try(&.as(ShoppingCart)) || ShoppingCart.new
  
  item = CartItem.new(
    id: env.params.body["id"].as(String),
    name: env.params.body["name"].as(String),
    price: env.params.body["price"].to_f
  )
  
  cart.add_item(item)
  env.session.object("cart", cart)
  
  "Added to cart! Total: $#{cart.total} (#{cart.item_count} items)"
end
```

## ⚙️ Configuration

Customize session behavior to fit your application's needs:

### Quick Configuration

```crystal
Kemal::Session.config do |config|
  config.cookie_name = "my_app_session"     # Custom cookie name
  config.secret = "your-super-secret-key"   # 🔑 Always set this in production!
  config.timeout = 2.hours                  # Session expires after 2 hours
  config.gc_interval = 5.minutes            # Clean expired sessions every 5 minutes
  config.secure = true                      # Only send over HTTPS
  config.domain = "example.com"             # Scope to specific domain
end
```

### One-line Configuration

```crystal
Kemal::Session.config.cookie_name = "session_id"
Kemal::Session.config.secret = "my-secret-key"
Kemal::Session.config.timeout = 30.minutes
```

### 📋 Configuration Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `timeout` | Session expires after this time since last activity | `1.hour` | `2.hours`, `30.minutes` |
| `cookie_name` | Name of the session cookie | `"kemal_sessid"` | `"my_app_session"` |
| `engine` | Storage backend for sessions | `MemoryEngine` | `FileEngine`, `RedisEngine` |
| `gc_interval` | How often to clean expired sessions | `4.minutes` | `10.minutes`, `1.hour` |
| `secret` | Secret key for signing session cookies | `""` ⚠️ | Generated secure string |
| `secure` | Send cookie only over HTTPS | `false` | `true` for production |
| `domain` | Scope cookie to specific domain | `nil` | `"example.com"` |
| `path` | Scope cookie to specific path | `"/"` | `"/app"` |
| `samesite` | SameSite cookie policy | `nil` | `HTTP::Cookie::SameSite::Strict` |

### 🔐 Security Best Practices

#### 1. Generate a Secure Secret

```bash
# Generate a random secret key
crystal eval 'require "random/secure"; puts Random::Secure.hex(64)'
```

```crystal
# Use environment variables in production
Kemal::Session.config.secret = ENV["SESSION_SECRET"]? || "fallback-for-development"
```

#### 2. Production Security Settings

```crystal
Kemal::Session.config do |config|
  config.secret = ENV["SESSION_SECRET"]                    # From environment
  config.secure = true                                     # HTTPS only
  config.samesite = HTTP::Cookie::SameSite::Strict         # CSRF protection
  config.domain = "yourdomain.com"                         # Scope to your domain
  config.timeout = 1.hour                                  # Reasonable timeout
end
```

#### 3. Cookie Security

```crystal
Kemal::Session.config do |config|
  config.samesite = HTTP::Cookie::SameSite::Strict   # Prevents CSRF attacks
  config.secure = true                               # HTTPS only
  config.domain = "example.com"                      # Limit to your domain
end
```

## 🗄️ Storage Engines

Choose the right storage engine for your application's needs:

### Memory Engine (Default)
Perfect for development and single-server applications:

```crystal
# Already the default, but you can configure it explicitly
Kemal::Session.config.engine = Kemal::Session::MemoryEngine.new
```

**Pros**: Fast, no setup required  
**Cons**: Sessions lost on server restart, not suitable for multiple servers

### File Engine
Store sessions on disk for persistence across restarts:

```crystal
Kemal::Session.config.engine = Kemal::Session::FileEngine.new({
  :sessions_dir => "/var/lib/my_app/sessions/"
})
```

**Pros**: Persists across restarts, simple setup  
**Cons**: File I/O overhead, not suitable for multiple servers

### Production-Ready Engines

For production applications, consider these external engines:

| Engine | Use Case | Setup |
|--------|----------|-------|
| **[Redis](https://github.com/neovintage/kemal-session-redis)** | High performance, multiple servers | `shard.yml: kemal-session-redis` |
| **[PostgreSQL](https://github.com/mang/kemal-session-postgres)** | Existing PostgreSQL infrastructure | `shard.yml: kemal-session-postgres` |
| **[MySQL](https://github.com/crisward/kemal-session-mysql)** | Existing MySQL infrastructure | `shard.yml: kemal-session-mysql` |
| **[RethinkDB](https://github.com/kingsleyh/kemal-session-rethinkdb)** | Real-time applications | `shard.yml: kemal-session-rethinkdb` |

### Redis Engine Example

```yaml
# shard.yml
dependencies:
  kemal-session:
    github: kemalcr/kemal-session
  kemal-session-redis:
    github: neovintage/kemal-session-redis
```

```crystal
require "kemal"
require "kemal-session"
require "kemal-session-redis"

Kemal::Session.config.engine = Kemal::Session::RedisEngine.new(
  host: "localhost",
  port: 6379,
  password: ENV["REDIS_PASSWORD"]?,
  database: 0
)
```

### Custom Engine

Create your own storage engine by implementing the required interface. Check the [wiki](https://github.com/kemalcr/kemal-session/wiki/Creating-your-session-engine) for detailed instructions.

## 🚪 Session Management

### 🚪 User Logout

```crystal
get "/logout" do |env|
  env.session.destroy
  redirect "/login"
end
```

### 👨‍💼 Administrative Session Management

For building admin interfaces, you can manage other users' sessions:

```crystal
# Get specific session by ID
admin_session = Kemal::Session.get("session_id_here")

# Iterate through all active sessions
Kemal::Session.each do |session|
  puts "Session: #{session.id}, Last Activity: #{session.last_access_time}"
end

# Get all sessions as an array
all_sessions = Kemal::Session.all
puts "Total active sessions: #{all_sessions.size}"

# Force logout a specific user
Kemal::Session.destroy("problematic_session_id")

# Emergency: Log out all users
Kemal::Session.destroy_all
```

⚠️ **Security Warning**: Administrative session functions access ALL user sessions. Use with extreme caution and proper authorization checks:

```crystal
get "/admin/sessions" do |env|
  # Always verify admin permissions first!
  admin_user = env.session.object?("current_user").try(&.as(User))
  halt env, status_code: 403, response: "Forbidden" unless admin_user.try(&.admin?)
  
  sessions = Kemal::Session.all
  # ... render admin interface
end
```

### 🗑️ Memory Considerations

- `Kemal::Session.all` and `Kemal::Session.each` load all sessions into memory
- For high-traffic applications, consider pagination or streaming approaches
- The memory impact depends on your storage engine implementation

## 🏆 Production Examples

### Complete Authentication System

```crystal
require "kemal"
require "kemal-session"

# Configure session for production
Kemal::Session.config do |config|
  config.secret = ENV["SESSION_SECRET"]
  config.secure = true if ENV["KEMAL_ENV"]? == "production"
  config.timeout = 2.hours
  config.samesite = HTTP::Cookie::SameSite::Strict
end

# Add CSRF protection
add_handler Kemal::Session::CSRF.new

# User model
class User
  include JSON::Serializable
  include Kemal::Session::StorableObject

  property id : Int32
  property username : String
  property email : String
  property admin : Bool

  def initialize(@id : Int32, @username : String, @email : String, @admin : Bool = false)
  end
end

# Login route
post "/login" do |env|
  username = env.params.body["username"].as(String)
  password = env.params.body["password"].as(String)
  
  # Authenticate user (implement your logic)
  if user = authenticate_user(username, password)
    env.session.object("current_user", user)
    env.session.string("login_time", Time.utc.to_s)
    redirect "/dashboard"
  else
    env.session.string("error", "Invalid credentials")
    redirect "/login"
  end
end

# Protected route
get "/dashboard" do |env|
  user = env.session.object?("current_user").try(&.as(User))
  halt env, status_code: 401, response: "Please log in" unless user
  
  "Welcome #{user.username}! You logged in at #{env.session.string?("login_time")}"
end

# Admin-only route
get "/admin" do |env|
  user = env.session.object?("current_user").try(&.as(User))
  halt env, status_code: 401, response: "Please log in" unless user
  halt env, status_code: 403, response: "Admin required" unless user.admin
  
  "Admin panel - manage users here"
end

Kemal.run
```

### API with Session-based Auth

```crystal
# API endpoints with session authentication
get "/api/profile" do |env|
  env.response.content_type = "application/json"
  
  user = env.session.object?("current_user").try(&.as(User))
  if user
    user.to_json
  else
    env.response.status_code = 401
    {"error" => "Authentication required"}.to_json
  end
end
```

## 📚 Helpful Resources

- 📖 [Crystal Language Documentation](https://crystal-lang.org/docs/)
- 🌐 [Kemal Framework](https://kemalcr.com/)
- 🔧 [Creating Custom Engines](https://github.com/kemalcr/kemal-session/wiki/Creating-your-session-engine)
- 💡 [Crystal Security Best Practices](https://crystal-lang.org/reference/guides/security.html)

## 🤝 Contributing

We love contributions! Here's how you can help:

1. 🍴 Fork the repository
2. 🌟 Create a feature branch (`git checkout -b my-new-feature`)
3. ✍️ Make your changes and add tests
4. ✅ Ensure all tests pass (`crystal spec`)
5. 📝 Commit your changes (`git commit -am 'Add some feature'`)
6. 🚀 Push to the branch (`git push origin my-new-feature`)
7. 🎯 Create a Pull Request

## 🙏 Acknowledgments

Special thanks to:
- [Thyra](https://github.com/Thyra) for the initial implementation
- The Crystal and Kemal communities for their support


