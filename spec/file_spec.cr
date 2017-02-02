require "./spec_helper"
require "file_utils"

# Set the engine for all of these tests
#
SESSION_DIR = "./spec/assets/sessions/"
Session.config.secret = "super-awesome-secret"
Session.config.engine = Session::FileEngine.new({:sessions_dir => "./spec/assets/sessions/"})

Spec.before_each do
  sessions_path = File.join(Dir.current, "spec", "assets", "sessions")
  Dir.foreach(sessions_path) do |file|
    next if file == "."
    File.delete File.join(Dir.current, "spec", "assets", "sessions", file)
  end
end

describe "Session::FileEngine" do
  describe "options" do
    describe ":sessions_dir" do
      it "raises an ArgumentError if option not passed" do
        expect_raises(ArgumentError) do
          Session::FileEngine.new({:no => "option"})
        end
      end

      it "raises an ArgumentError if the directory does not exist" do
        expect_raises(ArgumentError) do
          Session::FileEngine.new({:sessions_dir => "foobar"})
        end
      end
    end
  end
end
