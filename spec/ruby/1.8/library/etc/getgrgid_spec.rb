require File.dirname(__FILE__) + '/../../spec_helper'
require 'etc'

describe "Etc.getgrgid" do
  before(:all) do
    @gid = `id -g`.strip.to_i
    @name = `id -gn`.strip
  end

  deviates_on :rubinius, :ruby19 do
    it "returns a Group struct instance for the given user" do
      gr = Etc.getgrgid(@gid)

      deviates_on :rubinius do
        gr.is_a?(Etc::Group).should == true
      end

      compliant_on :ruby19 do
        gr.is_a?(Struct::Group).should == true
      end

      gr.gid.should == @gid
      gr.name.should == @name
    end
  end

  compliant_on :ruby do
    platform_is_not :darwin do
      it "ignores its argument" do
        lambda { Etc.getgrgid("foo") }.should raise_error(TypeError)
        Etc.getgrgid(42)
        Etc.getgrgid(9876)
      end
    end

    it "returns a Group struct instance for the current user's group" do
      gr = Etc.getgrgid(@gid)
      gr.is_a?(Struct::Group).should == true
      gr.gid.should == @gid
      gr.name.should == @name
    end
  end

  deviates_on :rubinius, :ruby19 do
    it "only accepts integers as argument" do
      lambda {
        Etc.getgrgid("foo")
        Etc.getgrgid(nil)
      }.should raise_error(TypeError)
    end
  end

  deviates_on :rubinius, :ruby19 do
    it "uses Process.gid as the default value for the argument" do
      gr = Etc.getgrgid

      gr.gid.should == @gid
      gr.name.should == @name
    end
  end
end
