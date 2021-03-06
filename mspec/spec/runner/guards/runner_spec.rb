require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../../../runner/guards/runner'

describe RunnerGuard, "#match?" do
  before :all do
    @verbose = $VERBOSE
    $VERBOSE = nil
  end
  
  after :all do
    $VERBOSE = @verbose
  end
  
  it "returns true when passed :mspec and ENV['MSPEC_RUNNER'] is true" do
    ENV['MSPEC_RUNNER'] = '1'
    RunnerGuard.new(:mspec).match?.should == true
  end
  
  it "returns false when passed :mspec and ENV['MSPEC_RUNNER'] is false" do
    ENV.delete 'MSPEC_RUNNER'
    RunnerGuard.new(:mspec).match?.should == false
  end
  
  it "returns true when passed :rspec and ENV['RSPEC_RUNNER'] is false but the constant Spec exists" do
    ENV.delete 'RSPEC_RUNNER'
    Object.const_set(:Spec, 1) unless Object.const_defined?(:Spec)
    RunnerGuard.new(:rspec).match?.should == true
  end

  it "returns true when passed :rspec and ENV['RSPEC_RUNNER'] is true but the constant Spec does not exist" do
    ENV['RSPEC_RUNNER'] = '1'
    Object.should_receive(:const_defined?).with(:Spec).any_number_of_times.and_return(false)
    RunnerGuard.new(:rspec).match?.should == true
  end
end

describe Object, "#runner_is" do
  before :each do
    @guard = RunnerGuard.new
    RunnerGuard.stub!(:new).and_return(@guard)
    ScratchPad.clear
  end
  
  it "yields when #match? returns true" do
    @guard.stub!(:match?).and_return(true)
    runner_is(:mspec) { ScratchPad.record :yield }
    ScratchPad.recorded.should == :yield
  end
  
  it "does not yield when #match? returns false" do
    @guard.stub!(:match?).and_return(false)
    runner_is(:mspec) { ScratchPad.record :yield }
    ScratchPad.recorded.should_not == :yield
  end
end

describe Object, "#runner_is_not" do
  before :each do
    @guard = RunnerGuard.new
    RunnerGuard.stub!(:new).and_return(@guard)
    ScratchPad.clear
  end
  
  it "does not yield when #match? returns true" do
    @guard.stub!(:match?).and_return(true)
    runner_is_not(:mspec) { ScratchPad.record :yield }
    ScratchPad.recorded.should_not == :yield
  end
  
  it "yields when #match? returns false" do
    @guard.stub!(:match?).and_return(false)
    runner_is_not(:mspec) { ScratchPad.record :yield }
    ScratchPad.recorded.should == :yield
  end
end
