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

  describe "#get" do
    it "should return a session" do
      session = Session.new(create_context(SESSION_ID))
      same_session = Session.get(SESSION_ID)
      session.id.should eq(same_session.id)
    end

    it "should return nil if a session doesnt exist" do
      no_session = Session.get(SESSION_ID)
      no_session.should be_nil
    end
  end

  describe "signed cookies" do
    it "should use the same session_id" do
      Session.config.secret = SESSION_SECRET
      context = create_context(SIGNED_SESSION)
      session = Session.new(context)
      context.response.cookies[Session.config.cookie_name].value.should eq(SIGNED_SESSION)
    end

    it "should return a new session if signed token has been tampered" do
      Session.config.secret = SESSION_SECRET
      tampered_session = "123" + SIGNED_SESSION[3..-1]
      context = create_context(tampered_session)
      session = Session.new(context)
      name = Session.config.cookie_name
      context.response.cookies[name].value.should_not eq(SIGNED_SESSION)
      context.response.cookies[name].value.should_not eq(tampered_session)
    end

    it "should raise SecretRequiredException if secret is not set" do
      Session.config.secret = ""
      context = create_context(SESSION_ID)
      expect_raises("Session::SecretRequiredException") do
        session = Session.new(context)
      end
    end
  end
end
