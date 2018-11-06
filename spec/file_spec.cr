require "./spec_helper"
require "file_utils"
require "random/secure"

# Set the folder to use for all of these tests
#
SESSION_DIR = File.join(Dir.tempdir, Random::Secure.hex) + "/"
Dir.mkdir(SESSION_DIR)

# Set the engine for all of these tests
#
Kemal::Session.config.secret = "super-awesome-secret"
Kemal::Session.config.engine = Kemal::Session::FileEngine.new({:sessions_dir => SESSION_DIR})

Spec.before_each do
  if Kemal::Session.config.engine.class == Kemal::Session::FileEngine
    Dir.mkdir(SESSION_DIR) unless Dir.exists?(SESSION_DIR)
    Kemal::Session.config.engine.as(Kemal::Session::FileEngine).clear_cache
  end
end

Spec.after_each do
  if Kemal::Session.config.engine.class == Kemal::Session::FileEngine && Dir.exists?(SESSION_DIR)
    FileUtils.rm_r(SESSION_DIR) if Dir.exists?(SESSION_DIR)
    Kemal::Session.config.engine.as(Kemal::Session::FileEngine).clear_cache
  end
end

def get_file_session_filename(session_id)
  File.join(SESSION_DIR, "#{session_id}.json")
end

def get_file_session_contents(session_id)
  File.read(get_file_session_filename(session_id))
end

def should_be_empty_file_session(session_id)
  get_file_session_contents(session_id).should \
    eq("{\"ints\":{},\"bigints\":{},\"strings\":{},\"floats\":{},\"bools\":{},\"objects\":{}}")
end

describe "Session::FileEngine" do
  describe "options" do
    describe ":sessions_dir" do
      it "raises an ArgumentError if option not passed" do
        expect_raises(ArgumentError) do
          Kemal::Session::FileEngine.new({:no => "option"})
        end
      end

      it "raises an ArgumentError if the directory does not exist" do
        expect_raises(ArgumentError) do
          Kemal::Session::FileEngine.new({:sessions_dir => "foobar"})
        end
      end
    end
  end

  describe ".int" do
    it "can save a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{\"bar\":12},\"bigints\":{},\"strings\":{},\"floats\":{},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      session.int("bar").should eq 12
    end
  end

  describe ".delete_int" do
    it "can delete a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      session.delete_int("bar")
      should_be_empty_file_session(SESSION_ID)
    end

    it "shouldnt raise an error on empty key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_int("bar")
      end
    end
  end

  describe ".bigint" do
    it "can save a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bigint("bigbar", 12_i64)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{\"bigbar\":12},\"strings\":{},\"floats\":{},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bigint("bigbar", 12_i64)
      session.bigint("bigbar").should eq 12
      session.bigint("bigbar").is_a?(Int64).should be_true
    end
  end

  describe ".delete_bigint" do
    it "can delete a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bigint("bar", 12_i64)
      session.delete_bigint("bar")
      should_be_empty_file_session(SESSION_ID)
    end

    it "shouldnt raise an error on empty key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_bigint("bar")
      end
    end
  end

  describe ".bool" do
    it "can save a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bool("bar", true)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{},\"floats\":{},\"bools\":{\"bar\":true},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bool("bar", true)
      session.bool("bar").should eq true
    end
  end

  describe ".delete_bool" do
    it "can delete a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bool("bar", true)
      session.delete_bool("bar")
      should_be_empty_file_session(SESSION_ID)
    end

    it "shouldnt raise an error on empty key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_bool("bar")
      end
    end
  end

  describe ".float" do
    it "can save a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.float("bar", 3.00)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{},\"floats\":{\"bar\":3.0},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.float("bar", 3.00)
      session.float("bar").should eq 3.00
    end
  end

  describe ".delete_float" do
    it "can delete a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.float("bar", 3.00)
      session.delete_float("bar")
      should_be_empty_file_session(SESSION_ID)
    end

    it "shouldnt raise an error on empty key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_float("bar")
      end
    end
  end

  describe ".string" do
    it "can save a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.string("bar", "kemal")
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{\"bar\":\"kemal\"},\"floats\":{},\"bools\":{},\"objects\":{}}")
    end

    it "can retrieve a saved value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.string("bar", "kemal")
      session.string("bar").should eq "kemal"
    end
  end

  describe ".delete_string" do
    it "can delete a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.string("bar", "blah")
      session.delete_string("bar")
      should_be_empty_file_session(SESSION_ID)
    end

    it "shouldnt raise an error on empty key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_string("bar")
      end
    end
  end

  describe ".object" do
    it "can be saved and retrieved" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      u = User.new(123, "charlie")
      session.object("user", u)
      get_file_session_contents(SESSION_ID).should \
        eq("{\"ints\":{},\"bigints\":{},\"strings\":{},\"floats\":{},\"bools\":{},\"objects\":{\"user\":{\"type\":\"User\",\"object\":{\"id\":123,\"name\":\"charlie\"}}}}")

    Kemal::Session.config.engine.as(Kemal::Session::FileEngine).clear_cache

    session = Kemal::Session.get(SESSION_ID).not_nil!
    new_u = session.object("user").as(User)
    new_u.id.should eq(123)
    new_u.name.should eq("charlie")
    end
  end

  describe ".delete_object" do
    it "can delete a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      u = User.new(123, "charlie")
      session.object("user", u)
      session.delete_object("user")
      should_be_empty_file_session(SESSION_ID)
    end

    it "shouldnt raise an error on empty key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_object("user")
      end
    end
  end

  describe ".destroy" do
    it "should remove session from filesystem" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_true
      session.destroy
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_false
    end
  end

  describe "#destroy" do
    it "should remove session from filesystem" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_true
      Kemal::Session.destroy(SESSION_ID)
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_false
    end

    it "should not error if session doesnt exist in filesystem" do
      Kemal::Session.destroy("whatever.json").should be_nil
    end
  end

  describe "#run_gc" do
    it "should remove all sessions that are older than gc config" do
      2.times { Kemal::Session.new(create_context(Random::Secure.hex)) }
      Kemal::Session.all.size.should eq(2)

      # should remove nothing, as the gc > now
      Kemal::Session.config.engine.run_gc
      Kemal::Session.all.size.should eq(2)

      # set the timeout to < when we created it
      Kemal::Session.config.timeout = 0.seconds
      Kemal::Session.config.engine.run_gc
      Kemal::Session.all.size.should eq(0)
    end
  end

  describe "#destroy_all" do
    it "should remove all sessions in filesystem" do
      5.times { Kemal::Session.new(create_context(Random::Secure.hex)) }
      Kemal::Session.all.size.should eq(5)

      Kemal::Session.destroy_all
      Kemal::Session.all.size.should eq(0)
    end

    it "should not remove things that are not 'session files'" do
      f = File.join(SESSION_DIR, ".gitkeep")
      arr = Kemal::Session.all
      arr.size.should eq(0)

      File.write(f, "testing")

      # Should still be zero.
      arr = Kemal::Session.all
      arr.size.should eq(0)

      # Shouldn't remove file
      Kemal::Session.destroy_all
      Kemal::Session.all.size.should eq(0)
      File.file?(f).should be_true
      File.delete(f)
    end
  end

  describe "#get" do
    it "should return a valid Session" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      get_session = Kemal::Session.get(SESSION_ID)
      get_session.should_not be_nil
      if get_session
        session.id.should eq(get_session.id)
        get_session.is_a?(Kemal::Session).should be_true
      end
    end

    it "should return nil if the Session does not exist" do
      session = Kemal::Session.get(SESSION_ID)
      session.should be_nil
    end
  end

  describe "#create" do
    it "should build an empty session" do
      Kemal::Session.config.engine.create_session(SESSION_ID)
      File.file?(SESSION_DIR + SESSION_ID + ".json").should be_true
    end
  end

  describe "#all" do
    it "should return an empty array if none exist" do
      arr = Kemal::Session.all
      arr.is_a?(Array).should be_true
      arr.size.should eq(0)
    end

    it "should return an array of Sessions" do
      3.times { Kemal::Session.new(create_context(Random::Secure.hex)) }
      arr = Kemal::Session.all
      arr.is_a?(Array).should be_true
      arr.size.should eq(3)
    end
  end

  describe "#each" do
    it "should iterate over all sessions" do
      5.times { Kemal::Session.new(create_context(Random::Secure.hex)) }
      count = 0
      Kemal::Session.each do |session|
        count = count + 1
      end
      count.should eq(5)
    end

    it "should not see things that are not 'session files'" do
      f = File.join(SESSION_DIR, ".gitkeep")
      File.write(f, "testing")

      count = 0
      Kemal::Session.each do |session|
        count = count + 1
      end
      count.should eq(0)

      File.delete(f)
    end
  end
end
