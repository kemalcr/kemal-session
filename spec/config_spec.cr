require "./spec_helper"

describe "Session" do
  describe "::Config" do
    describe "::INSTANCE" do
      it "returns a Session::Config object" do
        typeof(Kemal::Session::Config::INSTANCE).should eq Kemal::Session::Config
      end
    end
  end

  describe ".config" do
    it "returns Session::Config::INSTANCE" do
      Kemal::Session.config.should be Kemal::Session::Config::INSTANCE
    end

    it "yields Session::Config::INSTANCE" do
      Kemal::Session.config do |config|
        config.should be Kemal::Session::Config::INSTANCE
      end
    end
  end
end
