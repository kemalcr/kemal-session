require "./spec_helper"

describe "Session" do
  describe ".start" do
    it "returns a Session instance" do
      typeof(Session.new(create_context("foo"))).should eq Session
    end
  end

  describe ".int" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.int("bar", 12)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.int("bar", 12)
      session.int("bar").should eq 12
    end
  end

  describe "signed cookies" do
    it "should use the same session_id" do
      Session.config.secret_token = SESSION_SECRET
      context = create_context(SIGNED_SESSION)
      session = Session.new(context)
      context.response.cookies[Session.config.cookie_name].value.should eq(SIGNED_SESSION)
    end

    it "should return a new session if signed token has been tampered" do
      Session.config.secret_token = SESSION_SECRET
      tampered_session = "123" + SIGNED_SESSION[3..-1]
      context = create_context(tampered_session)
      session = Session.new(context)
      name = Session.config.cookie_name
      context.response.cookies[name].value.should_not eq(SIGNED_SESSION)
      context.response.cookies[name].value.should_not eq(tampered_session)
    end

    it "should not use signed cookies if secret_token is not set" do
      Session.config.secret_token = nil
      context = create_context("foo")
      session = Session.new(context)
      name = Session.config.cookie_name
      context.response.cookies[name].value.size.should eq(32)
      context.response.cookies[name].value.includes?("--").should be_false
    end
  end
end
