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
end
