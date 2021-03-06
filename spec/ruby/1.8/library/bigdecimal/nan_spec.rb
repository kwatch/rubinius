require File.dirname(__FILE__) + '/../../spec_helper'
require 'bigdecimal'

describe "BigDecimal#nan?" do

  it "returns true if self is not a number" do
    BigDecimal("NaN").nan?.should == true
    # BigDecimal("Infinity").nan?.should == true
    # This fails.
    # Is infinity really a number?
  end

  it "returns false otherwise" do
    BigDecimal("2E40001").nan?.should == false
    BigDecimal("3E-20001").nan?.should == false
    BigDecimal("0E-200000000").nan?.should == false
    BigDecimal("0E200000000000").nan?.should == false
    BigDecimal("0.000000000000000000000000").nan?.should == false
  end

end

