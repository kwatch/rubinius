require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Hash#fetch" do
  it "returns the value for key" do
    { :a => 1, :b => -1 }.fetch(:b).should == -1
  end
  
  it "raises an IndexError if key is not found" do
    lambda { {}.fetch(:a)             }.should raise_error(IndexError)
    lambda { Hash.new(5).fetch(:a)    }.should raise_error(IndexError)
    lambda { Hash.new { 5 }.fetch(:a) }.should raise_error(IndexError)
  end
  
  it "returns default if key is not found when passed a default" do
    {}.fetch(:a, nil).should == nil
    {}.fetch(:a, 'not here!').should == "not here!"
    { :a => nil }.fetch(:a, 'not here!').should == nil
  end
  
  it "returns value of block if key is not found when passed a block" do
    {}.fetch('a') { |k| k + '!' }.should == "a!"
  end

  it "gives precedence to the default block over the default argument when passed both" do
    old, $VERBOSE = $VERBOSE, nil
    {}.fetch(9, :foo) { |i| i * i }.should == 81
    $VERBOSE = old
  end

  it "raises an ArgumentError when not passed one or two arguments" do
    lambda { {}.fetch()        }.should raise_error(ArgumentError)
    lambda { {}.fetch(1, 2, 3) }.should raise_error(ArgumentError)
  end
end
