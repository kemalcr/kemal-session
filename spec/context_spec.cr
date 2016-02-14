require "./spec_helper.cr"

describe "Session" do
  describe ".id_from_context" do
    it "returns a set session id from the context" do
      context = create_context("session id")
      Session.id_from_context(context).should eq "session id"
    end

    it "returns nil if there is no session cookie" do
      context = create_context("")
      Session.id_from_context(context).should be_nil
    end
  end
end

