require "./spec_helper"
require "file_utils"

# Set the engine for all of these tests
#
SESSION_DIR = "./spec/assets/sessions/"
Session.config.secret = "super-awesome-secret"
Session.config.engine = Session::FileEngine.new({:sessions_dir => "./spec/assets/sessions/"})

Spec.before_each do
  sessions_path = File.join(Dir.current, "spec", "assets", "sessions")
  Dir.foreach(sessions_path) do |file|
    next if file == "."
    File.delete File.join(Dir.current, "spec", "assets", "sessions", file)
  end
  Session.config.engine.as(Session::FileEngine).clear_cache
end

def get_file_session_contents(session_id)
  File.read(File.join(Dir.current, "spec", "assets", "sessions", "#{session_id}.json"))
end

describe "Session::FileEngine" do
  describe "options" do
    describe ":sessions_dir" do
      it "raises an ArgumentError if option not passed" do
        expect_raises(ArgumentError) do
          Session::FileEngine.new({:no => "option"})
        end
      end

      it "raises an ArgumentError if the directory does not exist" do
        expect_raises(ArgumentError) do
          Session::FileEngine.new({:sessions_dir => "foobar"})
        end
      end
    end
  end

  describe ".int" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{\"bar\":12},\"bigints\":{},\"strings\":{},\"floats\":{},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      session.int("bar").should eq 12
    end
  end

  describe ".bool" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.bool("bar", true)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{},\"floats\":{},\"bools\":{\"bar\":true},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.bool("bar", true)
      session.bool("bar").should eq true
    end
  end

  describe ".float" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.float("bar", 3.00)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.float("bar", 3.00)
      session.float("bar").should eq 3.00
    end
  end
end
