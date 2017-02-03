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
    next if file == "." || file == ".."
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

  describe ".bigint" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.bigint("bigbar", 12_i64)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{\"bigbar\":12},\"strings\":{},\"floats\":{},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.bigint("bigbar", 12_i64)
      session.bigint("bigbar").should eq 12
      session.bigint("bigbar").is_a?(Int64).should be_true
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
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{},\"floats\":{\"bar\":3.0},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.float("bar", 3.00)
      session.float("bar").should eq 3.00
    end
  end

  describe ".string" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.string("bar", "kemal")
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{\"bar\":\"kemal\"},\"floats\":{},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.string("bar", "kemal")
      session.string("bar").should eq "kemal"
    end
  end

  describe ".object" do
    it "can be saved and retrieved" do
      session = Session.new(create_context(SESSION_ID))
      u = User.new(123, "charlie")
      session.object("user", u)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{},\"floats\":{},\"bools\":{},\"objects\":{\"user\":{\"id\":123,\"name\":\"charlie\"}}}")

      Session.config.engine.as(Session::FileEngine).clear_cache

      session = Session.get(SESSION_ID).not_nil!
      new_u = session.object("user").as(User)
      new_u.id.should eq(123)
      new_u.name.should eq("charlie")
    end
  end

  describe ".destroy" do
    it "should remove session from filesystem" do
      session = Session.new(create_context(SESSION_ID))
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_true
      session.destroy
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_false
    end
  end

  describe "#destroy" do
    it "should remove session from filesystem" do
      session = Session.new(create_context(SESSION_ID))
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_true
      Session.destroy(SESSION_ID)
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_false
    end

    it "should not error if session doesnt exist in filesystem" do
      Session.destroy("whatever.json").should be_nil
    end
  end

  describe "#destroy_all" do
    it "should remove all sessions in filesystem" do
      5.times { Session.new(create_context(SecureRandom.hex)) }
      arr = Session.all
      arr.size.should eq(5)
      Session.destroy_all
      Session.all.size.should eq(0)
    end
  end

  describe "#get" do
    it "should return a valid Session" do
      session = Session.new(create_context(SESSION_ID))
      get_session = Session.get(SESSION_ID)
      get_session.should_not be_nil
      if get_session
        session.id.should eq(get_session.id)
        get_session.is_a?(Session).should be_true
      end
    end

    it "should return nil if the Session does not exist" do
      session = Session.get(SESSION_ID)
      session.should be_nil
    end
  end

  describe "#create" do
    it "should build an empty session" do
      Session.config.engine.create_session(SESSION_ID)
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_true
    end
  end

  describe "#all" do
    it "should return an empty array if none exist" do
      arr = Session.all
      arr.is_a?(Array).should be_true
      arr.size.should eq(0)
    end

    it "should return an array of Sessions" do
      3.times { Session.new(create_context(SecureRandom.hex)) }
      arr = Session.all
      arr.is_a?(Array).should be_true
      arr.size.should eq(3)
    end
  end

  describe "#each" do
    it "should iterate over all sessions" do
      5.times { Session.new(create_context(SecureRandom.hex)) }
      count = 0
      Session.each do |session|
        count = count + 1
      end
      count.should eq(5)
    end
  end
end
