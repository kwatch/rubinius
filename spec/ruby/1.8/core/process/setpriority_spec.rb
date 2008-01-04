require File.dirname(__FILE__) + '/../../spec_helper'

describe "Process.setpriority" do
  it "takes three arguments" do
    lambda { Process.setpriority }.should raise_error(ArgumentError)
    lambda {
      Process.setpriority(Process::PRIO_PROCESS)
    }.should raise_error(ArgumentError)
    lambda {
      Process.setpriority(Process::PRIO_PROCESS, 0)
    }.should raise_error(ArgumentError)
  end

  it "sets the scheduling priority for a specified process" do
    p = Process.getpriority(Process::PRIO_PROCESS, 0)
    Process.setpriority(Process::PRIO_PROCESS, 0, p + 1).should == 0
    Process.getpriority(Process::PRIO_PROCESS, 0).should == (p + 1)
    if Process.uid == 0
      Process.setpriority(Process::PRIO_PROCESS, 0, p).should == 0
    else
      lambda {
        Process.setpriority(Process::PRIO_PROCESS, 0, p)
      }.should raise_error(Errno::EACCES)
    end
  end

  # Darwin doesn't seem to handle these at all, getting all out of
  # whack with either permission errors or just the wrong value
  platform_is_not :os => :darwin do
  it "sets the scheduling priority for a specified process group" do
    pr = Process.getpriority(Process::PRIO_PGRP, 0)

    Process.setpriority(Process::PRIO_PGRP, 0, pr + 1).should == 0
    Process.getpriority(Process::PRIO_PGRP, 0).should == (pr + 1)
    if Process.uid == 0
      Process.setpriority(Process::PRIO_PGRP, 0, pr).should == 0
    else
      lambda {
        Process.setpriority(Process::PRIO_PGRP, 0, pr)
      }.should raise_error(Errno::EACCES)
    end
  end
  end

  it "sets the scheduling priority for a specified user" do
    p = Process.getpriority(Process::PRIO_USER, 0)
    if Process.uid == 0
      Process.setpriority(Process::PRIO_USER, 0, p + 1).should == 0
      Process.getpriority(Process::PRIO_USER, 0).should == (p + 1)
      Process.setpriority(Process::PRIO_USER, 0, p).should == 0
    else
      lambda {
        Process.setpriority(Process::PRIO_USER, 0, p - 1)
      }.should raise_error(Errno::EACCES)
    end
  end

end