shared :env_each do |cmd|
  describe "ENV##{cmd}" do

    it "returns each pair" do
      orig = ENV.to_hash
      e = []
      begin
        ENV.clear
        ENV["foo"] = "bar"
        ENV["baz"] = "boo"
        ENV.send(cmd) { |k, v| e << [k, v] }
        e.should == [["foo", "bar"], ["baz", "boo"]]
      ensure
        ENV.replace orig
      end
    end

    it "raises LocalJumpError if no block given" do
      lambda { ENV.each_key }.should raise_error(LocalJumpError)
    end

  end
end
