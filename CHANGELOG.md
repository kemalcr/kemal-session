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