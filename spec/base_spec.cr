require "./spec_helper"

describe "Session" do
  before_all do
    Kemal::Session.config.engine = Kemal::Session::MemoryEngine.new
    Kemal::Session.config.secret = "kemal_rocks"
  end

  describe ".start" do
    it "returns a Session instance" do
      typeof(Kemal::Session.new(create_context(SESSION_ID))).should eq Kemal::Session
    end
  end

  describe ".int" do
    it "can save a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
    end

    it "can retrieve a saved value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      session.int("bar").should eq 12
    end

    it "throws an exception if the key doesnt exist" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_raises(KeyError, /Missing hash key: "something"/) do
        session.int("something")
      end
    end
  end

  describe ".delete_int" do
    it "can delete the contents of a key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.int("user_id", 123)
      session.delete_int("user_id")
      session.int?("user_id").should be_nil
    end

    it "should succeed if the key does not exist" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_int("user_id")
      end
    end
  end

  describe ".int?" do
    it "can return nil" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      val = session.int?("something")
      val.should be_nil
    end

    it "can return a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      session.int?("bar").is_a?(Int32).should be_true
    end
  end

  describe ".bigint" do
    it "can save a value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bigint("bigbar", 12_i64)
    end

    it "can retrieve a saved value" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bigint("bigbar", 12_i64)
      session.bigint("bigbar").should eq 12
      session.bigint("bigbar").is_a?(Int64).should be_true
    end
  end

  describe ".delete_bigint" do
    it "can delete the contents of a key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.bigint("user_id", 123_i64)
      session.delete_bigint("user_id")
      session.bigint?("user_id").should be_nil
    end

    it "should succeed if the key does not exist" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_bigint("user_id")
      end
    end
  end

  describe ".objects" do
    it "can retrieve multiple StorableObjects" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.object("obj1", User.new(1, "cool"))
      session.object("obj2", User.new(2, "dude"))
      result = session.objects
      result.size.should eq(2)
    end
  end

  describe ".object?" do
    it "will return an object when one exists" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      user = User.new(1, "cool")
      session.object("obj1", user)
      session.object?("obj1").should_not be_nil
    end

    it "will return nil when an object doesnt exist" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.object?("obj1").should be_nil
    end
  end

  describe ".object" do
    it "can be saved" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.object("obj", User.new(1, "cool"))
      user = session.object?("obj")
      user.should_not be_nil
      if user
        user = user.as(User)
        user.id.should eq(1)
        user.name.should eq("cool")
      end
    end

    it "will be serialized in memory engine" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_raises Exception, "calling to_json" do
        session.object("obj", UserTestSerialization.new(1_i64))
      end
    end

    it "will be deserialized in memory engine" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.object("obj", UserTestDeserialization.new(1_i64))
      expect_raises Exception, "calling from_json" do
        s = Kemal::Session.get(SESSION_ID)
        s.as(Kemal::Session).object("obj")
      end
    end

    it "can deserialize multiple objects correctly" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.object("obj1", First.new(1_i64))
      session.object("obj2", Second.new(2_i64))

      session.object("obj1").class.should eq(First)
      session.object("obj2").class.should eq(Second)
    end
  end

  describe ".delete_object" do
    it "can delete the contents of a key" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      session.object("obj", User.new(1, "cool"))
      session.delete_object("obj")
      session.object?("obj").should be_nil
    end

    it "should succeed if the key does not exist" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      expect_not_raises do
        session.delete_bigint("obj")
      end
    end
  end

  describe ".reset" do
    it "should delete the current session from session storage and the cookie value should be different" do
      context = create_context(SESSION_ID)
      session = Kemal::Session.new(context)
      session.int("user_id", 123)
      current_cookie = context.response.cookies[Kemal::Session.config.cookie_name].value
      session.reset
      new_cookie = context.response.cookies[Kemal::Session.config.cookie_name].value
      new_cookie.should_not eq(current_cookie)
      new_cookie.size.should_not eq(0)
      Kemal::Session.get(SESSION_ID).should be_nil
      session.int("user_id", 456)
      session = Kemal::Session.get(session.id)
      session.should_not be_nil
    end
  end

  describe ".destroy" do
    it "should delete a session and remove cookie in current session" do
      context = create_context(SESSION_ID)
      session = Kemal::Session.new(context)
      session.int("user_id", 123)
      session.destroy
      context.response.cookies[Kemal::Session.config.cookie_name].value.should eq("")
      new_session = Kemal::Session.new(create_context(SESSION_ID))
      new_session.int?("user_id").should be_nil
    end

    it "should delete a session even if context doesnt exist" do
      create_context(SESSION_ID)
      session = Kemal::Session.get(SESSION_ID)
      session.should_not be_nil
      if session
        session.destroy
        Kemal::Session.get(SESSION_ID).should be_nil
      end
    end
  end

  describe "#destroy" do
    it "will delete a session" do
      context = create_context(SESSION_ID)
      session = Kemal::Session.new(context)
      session.int("user_id", 123)
      Kemal::Session.destroy(SESSION_ID)
      new_session = Kemal::Session.new(create_context(SESSION_ID))
      new_session.int?("user_id").should be_nil
    end
  end

  describe "#destroy_all" do
    it "should remove all sessions" do
      session = Kemal::Session.new(create_context(SESSION_ID))
      Kemal::Session.all.size.should be > 0
      Kemal::Session.destroy_all
      Kemal::Session.all.size.should eq(0)
    end
  end

  describe "#get" do
    it "should return a session" do
      context = create_context(SESSION_ID)
      session = Kemal::Session.new(context)
      same_session = Kemal::Session.get(SESSION_ID)
      same_session.should_not be_nil
      if same_session
        session.id.should eq(same_session.id)
      end
    end

    it "should return nil if a session doesnt exist" do
      no_session = Kemal::Session.get("some-crazy-session")
      no_session.should be_nil
    end
  end

  describe "#all" do
    it "should get every session saved in storage" do
      Kemal::Session.destroy_all
      Kemal::Session.all.size.should eq(0)
      3.times do
        Kemal::Session.new(create_context(Random::Secure.hex))
      end
      Kemal::Session.all.size.should eq(3)
    end
  end

  describe "#each" do
    it "should iterate through all sessions" do
      Kemal::Session.destroy_all
      5.times do
        Kemal::Session.new(create_context(Random::Secure.hex))
      end
      count = 0
      Kemal::Session.each do |session|
        session.class.should eq Kemal::Session
        count = count + 1
      end
      count.should eq(5)
    end
  end

  describe "signed cookies" do
    signed_session = "#{SESSION_ID}--#{Kemal::Session.sign_value(SESSION_ID)}"

    it "should use the same session_id" do
      context = create_context(SESSION_ID)
      session = Kemal::Session.new(context)
      context.response.cookies[Kemal::Session.config.cookie_name].value.should eq(signed_session)
    end

    it "should return a new session if signed token has been tampered" do
      tampered_session = "123" + signed_session[3..-1]
      context = create_context(tampered_session)
      session = Kemal::Session.new(context)
      name = Kemal::Session.config.cookie_name
      context.response.cookies[name].value.should_not eq(signed_session)
      context.response.cookies[name].value.should_not eq(tampered_session)
    end

    it "should raise SecretRequiredException if secret is not set" do
      Kemal::Session.config.secret = ""
      expect_raises(Kemal::Session::SecretRequiredException) do
        context = create_context("")
        session = Kemal::Session.new(context)
      end
    end
  end
end
