require File.dirname(__FILE__) + '/../../spec_helper'

describe "ENV#each_value" do

  it "returns each value" do
    e = []
    orig = ENV.to_hash
    begin
      ENV.clear
      ENV["1"] = "3"
      ENV["2"] = "4"
      ENV.each_value { |v| e << v }
      e.should == ["3", "4"]
    ensure
      ENV.replace orig
    end
  end

  it "raises LocalJumpError if no block given" do
    lambda { ENV.each_key }.should raise_error(LocalJumpError)
  end

end
