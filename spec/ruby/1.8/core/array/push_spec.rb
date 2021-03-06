require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#push" do
  it "appends the arguments to the array" do
    a = [ "a", "b", "c" ]
    a.push("d", "e", "f").equal?(a).should == true
    a.push().should == ["a", "b", "c", "d", "e", "f"]
    a.push(5)
    a.should == ["a", "b", "c", "d", "e", "f", 5]
  end

  it "isn't confused by previous shift" do
    a = [ "a", "b", "c" ]
    a.shift
    a.push("foo")
    a.should == ["b", "c", "foo"]
  end
  
  compliant_on :ruby, :jruby do
    it "raises a TypeError on a frozen array if modification takes place" do
      lambda { ArraySpecs.frozen_array.push(1) }.should raise_error(TypeError)
    end

    it "does not raise on a frozen array if no modification is made" do
      ArraySpecs.frozen_array.push() # ok
    end
  end
end
