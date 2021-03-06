require File.dirname(__FILE__) + '/../../spec_helper'

describe "ENV#delete_if" do

  it "deletes pairs if the block returns true" do
    ENV["foo"] = "bar"
    ENV.delete_if { |k, v| k == "foo" }
    ENV["foo"].should == nil
  end

  it "returns ENV even if nothing deleted" do
    ENV.delete_if { false }.should_not == nil
  end

  it "raises LocalJumpError if no block given" do
    lambda { ENV.delete_if }.should raise_error(LocalJumpError)
  end

end
