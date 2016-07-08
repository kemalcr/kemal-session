require "../spec_helper.cr"

describe "Session::FileSystemEngine" do
  describe "options" do
    describe ":sessions_dir" do
      it "raises an ArgumentError if option not passed" do
        expect_raises(ArgumentError) do
          Session::FileSystemEngine.new({:no => "option"})
        end
      end

      it "raises an ArgumentError if the directory does not exist" do
        expect_raises(ArgumentError) do
          Session::FileSystemEngine.new({:sessions_dir => "foobar"})
        end
      end
    end
  end
end
