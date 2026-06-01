module Kemal
  class Session
    module ExpiryHelpers
      private def session_expired?(last_access_at : Int64) : Bool
        last_access_at < expiry_cutoff_ms
      end

      private def session_expired?(last_access_at : Time) : Bool
        (Time.utc - last_access_at) > Session.config.timeout
      end

      private def expiry_cutoff_ms : Int64
        (Time.utc - Session.config.timeout).to_unix_ms
      end
    end
  end
end
