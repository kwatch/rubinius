require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/shared/divide'

describe "Bignum#div" do
  it_behaves_like(:bignum_divide, :div)
end
