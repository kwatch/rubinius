require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

# arccosine : (-1.0, 1.0) --> (0, PI)	 	                
describe "Math.acos" do  
  it "returns a float" do 
    Math.acos(1).class.should == Float 
  end 
  
  it "returns the arccosine of the argument" do 
    Math.acos(1).should be_close(0.0, TOLERANCE) 
    Math.acos(0).should be_close(1.5707963267949, TOLERANCE) 
    Math.acos(-1).should be_close(Math::PI,TOLERANCE) 
    Math.acos(0.25).should be_close(1.31811607165282, TOLERANCE) 
    Math.acos(0.50).should be_close(1.0471975511966 , TOLERANCE) 
    Math.acos(0.75).should be_close(0.722734247813416, TOLERANCE) 
  end  
  
  it "raises an Errno::EDOM if the argument is greater than 1.0" do    
    lambda { Math.acos(1.0001) }.should raise_error(Errno::EDOM)
  end  
  
  it "raises an Errno::EDOM if the argument is less than -1.0" do    
    lambda { Math.acos(-1.0001) }.should raise_error(Errno::EDOM)
  end
  
  it "raises an ArgumentError if the argument cannot be coerced with Float()" do    
    lambda { Math.acos("test") }.should raise_error(ArgumentError)
  end
  
  it "raises a TypeError if the argument is nil" do
    lambda { Math.acos(nil) }.should raise_error(TypeError)
  end  

  it "accepts any argument that can be coerced with Float()" do
    Math.acos(MathSpecs::Float.new).should == 0.0
  end
end

describe "Math#acos" do
  it "is accessible as a private instance method" do
    IncludesMath.new.send(:acos, 0).should be_close(1.5707963267949, TOLERANCE)
  end
end
