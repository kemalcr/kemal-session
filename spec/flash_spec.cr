require "./spec_helper"

describe "Flash" do
  before_each do
    Kemal::Session.config.engine = Kemal::Session::MemoryEngine.new
    Kemal::Session.config.secret = "kemal_rocks"
  end

  describe "#[]=" do
    it "can set a flash value" do
      context = create_context(SESSION_ID)
      session = context.session
      flash = context.flash
      flash["notice"] = "welcome"
      session.string?("#{Kemal::Session::Flash::FLASH_PREFIX}notice").should eq("welcome")
    end
  end

  describe "#[]?" do
    it "returns nil when flash key does not exist" do
      context = create_context(SESSION_ID)
      flash = context.flash
      flash["notice"]?.should be_nil
    end

    it "returns the value and deletes it" do
      context = create_context(SESSION_ID)
      session = context.session
      flash = context.flash
      flash["notice"] = "welcome"
      flash["notice"]?.should eq("welcome")
      # Second access should return nil (deleted after first read)
      flash["notice"]?.should be_nil
    end

    it "removes the flash from session storage after reading" do
      context = create_context(SESSION_ID)
      session = context.session
      flash = context.flash
      flash["notice"] = "welcome"
      flash["notice"]?
      session.string?("#{Kemal::Session::Flash::FLASH_PREFIX}notice").should be_nil
    end
  end

  describe "#[]" do
    it "returns the value when it exists" do
      context = create_context(SESSION_ID)
      flash = context.flash
      flash["notice"] = "welcome"
      flash["notice"].should eq("welcome")
    end

    it "raises KeyError when flash key does not exist" do
      context = create_context(SESSION_ID)
      flash = context.flash
      expect_raises(KeyError, /Flash key not found: notice/) do
        flash["notice"]
      end
    end

    it "raises KeyError on second access (already consumed)" do
      context = create_context(SESSION_ID)
      flash = context.flash
      flash["notice"] = "welcome"
      flash["notice"].should eq("welcome")
      expect_raises(KeyError, /Flash key not found: notice/) do
        flash["notice"]
      end
    end
  end

  describe "multiple flash values" do
    it "can handle multiple flash keys" do
      context = create_context(SESSION_ID)
      flash = context.flash
      flash["notice"] = "Success!"
      flash["error"] = "Something went wrong"
      flash["warning"] = "Be careful"

      flash["notice"]?.should eq("Success!")
      flash["error"]?.should eq("Something went wrong")
      flash["warning"]?.should eq("Be careful")

      # All should be consumed now
      flash["notice"]?.should be_nil
      flash["error"]?.should be_nil
      flash["warning"]?.should be_nil
    end
  end

  describe "flash across requests" do
    it "persists flash to next request via session" do
      # First request: set flash
      context1 = create_context(SESSION_ID)
      flash1 = context1.flash
      flash1["notice"] = "Welcome!"

      # Second request: read flash (same session - using Session.get to avoid re-creating)
      session2 = Kemal::Session.get(SESSION_ID)
      session2.should_not be_nil
      if session2
        flash2 = Kemal::Session::Flash.new(session2)
        flash2["notice"]?.should eq("Welcome!")

        # Third request: flash should be gone (already consumed)
        session3 = Kemal::Session.get(SESSION_ID)
        session3.should_not be_nil
        if session3
          flash3 = Kemal::Session::Flash.new(session3)
          flash3["notice"]?.should be_nil
        end
      end
    end
  end
end
