require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Kernel#scan" do
  it "is a private method" do
    Kernel.private_instance_methods.should include("scan")
  end
end

describe "Kernel.scan" do
  it "needs to be reviewed for spec completeness" do
  end
end
