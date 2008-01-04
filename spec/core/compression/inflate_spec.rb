require File.dirname(__FILE__) + '/../../spec_helper'

describe "Compression::ZLib.inflate" do
  it "uncompresses data" do
    data = Compression::ZLib.deflate("blah")
    Compression::ZLib.inflate(data).should == 'blah'
  end
end