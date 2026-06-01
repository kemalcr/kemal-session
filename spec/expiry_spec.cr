require "./spec_helper"
require "file_utils"

EXPIRY_SESSION_DIR = File.join(Dir.tempdir, "kemal-session-expiry") + "/"

describe "session expiry" do
  after_each do
    Kemal::Session.config.timeout = 1.hour
    Kemal::Session.config.gc_interval = 4.minutes
  end

  describe "MemoryEngine" do
    before_each do
      Kemal::Session.config.engine = Kemal::Session::MemoryEngine.new
      Kemal::Session.config.secret = "kemal_rocks"
      Kemal::Session.config.timeout = 1.hour
    end

    it "rejects expired sessions on read without waiting for GC" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.string("key", "value")

      Kemal::Session.config.timeout = 1.millisecond
      sleep 2.milliseconds

      Kemal::Session.get(SESSION_ID).should be_nil
      session.string?("key").should be_nil
    end

    it "does not revive expired session data on write" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.string("key", "old")

      Kemal::Session.config.timeout = 1.millisecond
      sleep 2.milliseconds

      session.string?("key").should be_nil
      session.string("key", "new")
      session.string?("key").should eq "new"
    end
  end

  describe "FileEngine" do
    before_each do
      FileUtils.mkdir_p(EXPIRY_SESSION_DIR)
      Kemal::Session.config.engine = Kemal::Session::FileEngine.new({:sessions_dir => EXPIRY_SESSION_DIR})
      Kemal::Session.config.secret = "kemal_rocks"
      Kemal::Session.config.timeout = 1.hour
    end

    after_each do
      FileUtils.rm_rf(EXPIRY_SESSION_DIR) if Dir.exists?(EXPIRY_SESSION_DIR)
    end

    it "rejects expired sessions on read without waiting for GC" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.string("key", "value")

      past = Time.utc - 2.hours
      File.utime(past, past, File.join(EXPIRY_SESSION_DIR, SESSION_ID + ".json"))

      Kemal::Session.get(SESSION_ID).should be_nil
      session.string?("key").should be_nil
      File.exists?(File.join(EXPIRY_SESSION_DIR, SESSION_ID + ".json")).should be_false
    end

    it "does not revive expired session data on write" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.string("key", "old")

      past = Time.utc - 2.hours
      path = File.join(EXPIRY_SESSION_DIR, SESSION_ID + ".json")
      File.utime(past, past, path)

      session.string?("key").should be_nil
      session.string("key", "new")
      session.string?("key").should eq "new"
    end
  end
end
