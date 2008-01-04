require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Bignum#divmod" do
  before(:each) do
    @bignum = BignumHelper.sbm(55)
  end
  
  it "returns an Array containing quotient and modulus obtained from dividing self by the given argument" do
    @bignum.divmod(4).should == [2305843009213693965, 3]
    @bignum.divmod(13).should == [709490156681136604, 11]

    @bignum.divmod(4.0).should == [2305843009213693952, 0.0]
    @bignum.divmod(13.0).should == [709490156681136640, 8.0]

    @bignum.divmod(2.0).should == [4611686018427387904, 0.0]
    @bignum.divmod(0xffffffff).should == [2147483648,  2147483703]
  end
  
  it "raises a ZeroDivisionError when the given argument is 0" do
    lambda { @bignum.divmod(0) }.should raise_error(ZeroDivisionError)
    lambda { (-@bignum).divmod(0) }.should raise_error(ZeroDivisionError)
  end
  
  it "raises a FloatDomainError when the given argument is 0 and a Float" do
    lambda { @bignum.divmod(0.0) }.should raise_error(FloatDomainError, "NaN")
    lambda { (-@bignum).divmod(0.0) }.should raise_error(FloatDomainError, "NaN")
  end

  it "raises a TypeError when given a non-Integer" do
    lambda {
      (obj = mock('10')).should_receive(:to_int).any_number_of_times.and_return(10)
      @bignum.divmod(obj)
    }.should raise_error(TypeError)
    lambda { @bignum.divmod("10") }.should raise_error(TypeError)
    lambda { @bignum.divmod(:symbol) }.should raise_error(TypeError)
  end
end