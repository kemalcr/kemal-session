require "./spec_helper"

describe "Session" do
  describe ".start" do
    it "returns a Session instance" do
      typeof(Session.new(create_context(SESSION_ID))).should eq Session
    end
  end

  describe ".int" do
    it "can save a value" do
      session = Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context(SESSION_ID))
      session.int("bar", 12)
      session.int("bar").should eq 12
    end
  end

  describe ".destroy" do
    it "should delete a session and remove cookie in current session" do
      context = create_context(SESSION_ID)
      session = Session.new(context)
      session.int("user_id", 123)
      session.destroy
      context.response.cookies[Session.config.cookie_name].value.should eq("")
      new_session = Session.new(create_context(SESSION_ID))
      new_session.int?("user_id").should be_nil
    end
  end

  describe "#destroy" do
    it "will delete a session" do
      context = create_context(SESSION_ID)
      session = Session.new(context)
      session.int("user_id", 123)
      Session.destroy(SESSION_ID)
      new_session = Session.new(create_context(SESSION_ID))
      new_session.int?("user_id").should be_nil
    end
  end

  describe "#destroy_all" do
    it "should remove all sessions" do
      session = Session.new(create_context(SESSION_ID))
      Session.all.size.should be > 0
      Session.destroy_all
      Session.all.size.should eq(0)
    end
  end

  describe "#get" do
    it "should return a session" do
      context = create_context(SESSION_ID)
      session = Session.new(context)
      same_session = Session.get(SESSION_ID)
      same_session.should_not be_nil
      if same_session
        session.id.should eq(same_session.id)
      end
    end

    it "should return nil if a session doesnt exist" do
      no_session = Session.get("some-crazy-session")
      no_session.should be_nil
    end
  end

  describe "#all" do
    it "should get every session saved in storage" do
      Session.destroy_all
      Session.all.size.should eq(0)
      3.times do
        Session.new(create_context(SecureRandom.hex))
      end
      Session.all.size.should eq(3)
    end
  end

  describe "#each" do
    it "should iterate through all sessions" do
      Session.destroy_all
      5.times do
        Session.new(create_context(SecureRandom.hex))
      end
      count = 0
      Session.each do |session|
        session.class.should eq Session
        count = count + 1
      end
      count.should eq(5)
    end
  end

  describe "signed cookies" do
    it "should use the same session_id" do
      context = create_context(SESSION_ID)
      session = Session.new(context)
      context.response.cookies[Session.config.cookie_name].value.should eq(SIGNED_SESSION)
    end

    it "should return a new session if signed token has been tampered" do
      tampered_session = "123" + SIGNED_SESSION[3..-1]
      context = create_context(tampered_session)
      session = Session.new(context)
      name = Session.config.cookie_name
      context.response.cookies[name].value.should_not eq(SIGNED_SESSION)
      context.response.cookies[name].value.should_not eq(tampered_session)
    end

    it "should raise SecretRequiredException if secret is not set" do
      Session.config.secret = ""
      expect_raises("Session::SecretRequiredException") do
        context = create_context("")
        session = Session.new(context)
      end
    end
  end
end
