require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#&" do
  it "creates an array with elements common to both arrays (intersection)" do
    ([] & []).should == []
    ([1, 2] & []).should == []
    ([] & [1, 2]).should == []
    ([ 1, 3, 5 ] & [ 1, 2, 3 ]).should == [1, 3]
  end
  
  it "creates an array with no duplicates" do
    ([ 1, 1, 3, 5 ] & [ 1, 2, 3 ]).uniq!.should == nil
  end
  
  it "creates an array with elements in order they are first encountered" do
    ([ 1, 2, 3, 2, 5 ] & [ 5, 2, 3, 4 ]).should == [2, 3, 5]
  end

  it "does not modify the original Array" do
    a = [1, 1, 3, 5]
    a & [1, 2, 3]
    a.should == [1, 1, 3, 5]
  end

  it "calls to_ary on its argument" do
    obj = mock('[1,2,3]')
    def obj.to_ary() [1, 2, 3] end
    ([1, 2] & obj).should == ([1, 2])
    
    obj = mock('[1,2,3]')
    obj.should_receive(:respond_to?).with(:to_ary).any_number_of_times.and_return(true)
    obj.should_receive(:method_missing).with(:to_ary).and_return([1, 2, 3])
    ([1, 2] & obj).should == [1, 2]
  end

  # MRI doesn't actually call eql?() however. So you can't reimplement it.
  it "acts as if using eql?" do
    ([5.0, 4.0] & [5, 4]).should == []
    str = "x"
    ([str] & [str.dup]).should == [str]
  end
  
  it "does return subclass instances for Array subclasses" do
    (ArraySpecs::MyArray[1, 2, 3] & []).class.should == Array
    (ArraySpecs::MyArray[1, 2, 3] & ArraySpecs::MyArray[1, 2, 3]).class.should == Array
    ([] & ArraySpecs::MyArray[1, 2, 3]).class.should == Array
  end

  it "does not call to_ary on array subclasses" do
    ([5, 6] & ArraySpecs::ToAryArray[1, 2, 5, 6]).should == [5, 6]
  end  
end
