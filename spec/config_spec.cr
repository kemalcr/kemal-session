require "./spec_helper"

describe "Session" do
  describe "::Config" do
    describe "::INSTANCE" do
      it "returns a Session::Config object" do
        typeof(Session::Config::INSTANCE).should eq Session::Config
      end
    end
  end

  describe ".config" do
    it "returns Session::Config::INSTANCE" do
      Session.config.should be Session::Config::INSTANCE
    end

    it "yields Session::Config::INSTANCE" do
      Session.config do |config|
        config.should be Session::Config::INSTANCE
      end
    end
  end
end
