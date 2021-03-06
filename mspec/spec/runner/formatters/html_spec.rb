require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../../../runner/guards/guard'
require File.dirname(__FILE__) + '/../../../runner/formatters/html'
require File.dirname(__FILE__) + '/../../../runner/mspec'
require File.dirname(__FILE__) + '/../../../runner/state'

describe HtmlFormatter do
  before :each do
    @formatter = HtmlFormatter.new
  end
  
  it "responds to #register by registering itself with MSpec for appropriate actions" do
    MSpec.stub!(:register)
    MSpec.should_receive(:register).with(:start, @formatter)
    MSpec.should_receive(:register).with(:enter, @formatter)
    MSpec.should_receive(:register).with(:leave, @formatter)
    @formatter.register
  end
end

describe HtmlFormatter, "#start" do
  before :each do
    $stdout = @out = CaptureOutput.new
    @formatter = HtmlFormatter.new
  end
  
  after :each do
    $stdout = STDOUT
  end
  
  it "prints the HTML head" do
    @formatter.start
    @out.should == 
%[<html>
<head>
<title>Spec Output For #{RUBY_NAME} (#{RUBY_VERSION})</title>
<script type="text/css">
ul {
  list-style: none;
}
.fail {
  color: red;
}
.pass {
  color: green;
}
</script>
</head>
<body>
]
  end
end

describe HtmlFormatter, "#enter" do
  before :each do
    $stdout = @out = CaptureOutput.new
    @formatter = HtmlFormatter.new
  end
  
  after :each do
    $stdout = STDOUT
  end
  
  it "prints the #describe string" do
    @formatter.enter "describe"
    @out.should == "<div><p>describe</p>\n<ul>\n"
  end
end

describe HtmlFormatter, "#leave" do
  before :each do
    $stdout = @out = CaptureOutput.new
    @formatter = HtmlFormatter.new
  end
  
  after :each do
    $stdout = STDOUT
  end
  
  it "prints the closing tags for the #describe string" do
    @formatter.leave
    @out.should == "</ul>\n</div>\n"
  end
end

describe HtmlFormatter, "#after" do
  before :each do
    $stdout = @out = CaptureOutput.new
    @formatter = HtmlFormatter.new
    @state = SpecState.new("describe", "it")
  end
  
  after :each do
    $stdout = STDOUT
  end
  
  it "prints the #it once when there are no exceptions raised" do
    @formatter.after(@state)
    @out.should == %[<li class="pass">- it</li>\n]
  end
  
  it "prints the #it string once for each exception raised" do
    MSpec.stub!(:register)
    tally = mock("tally", :null_object => true)
    tally.stub!(:failures).and_return(1)
    tally.stub!(:errors).and_return(1)
    TallyAction.stub!(:new).and_return(tally)
    
    @formatter.register
    @state.exceptions << ["msg", ExpectationNotMetError.new("disappointing")]
    @state.exceptions << ["msg", Exception.new("painful")]
    @formatter.after(@state)
    @out.should == %[<li class="fail">- it (FAILED - 1)</li>\n<li class="fail">- it (ERROR - 2)</li>\n]
  end
end  

describe HtmlFormatter, "#finish" do
  before :each do
    @tally = mock("tally", :null_object => true)
    TallyAction.stub!(:new).and_return(@tally)
    @timer = mock("timer", :null_object => true)
    TimerAction.stub!(:new).and_return(@timer)
    
    $stdout = @out = CaptureOutput.new
    @state = SpecState.new("describe", "it")
    MSpec.stub!(:register)
    @formatter = HtmlFormatter.new
    @formatter.register
  end
  
  after :each do
    $stdout = STDOUT
  end
  
  it "prints a failure message for an exception" do
    @state.exceptions << ["msg", Exception.new("broken")]
    @formatter.instance_variable_set :@states, [@state]
    @formatter.finish
    @out.should =~ %r[<p>describe it ERROR</p>]
  end
  
  it "prints a backtrace for an exception" do
    @formatter.stub!(:backtrace).and_return("path/to/some/file.rb:35:in method")
    @state.exceptions << ["msg", Exception.new("broken")]
    @formatter.instance_variable_set :@states, [@state]
    @formatter.finish
    @out.should =~ %r[<pre>.*path/to/some/file.rb:35:in method.*</pre>]m
  end

  it "prints a summary of elapsed time" do
    @timer.should_receive(:format).and_return("Finished in 2.0 seconds")
    @formatter.finish
    @out.should =~ %r[<p>Finished in 2.0 seconds</p>\n]
  end
  
  it "prints a tally of counts" do
    @tally.should_receive(:format).and_return("1 example, 0 failures")
    @formatter.finish
    @out.should =~ %r[<p class="pass">1 example, 0 failures</p>]
  end
  
  it "prints errors, backtraces, elapsed time, and tallies" do
    @state.exceptions << ["msg", Exception.new("broken")]
    @formatter.stub!(:backtrace).and_return("path/to/some/file.rb:35:in method")
    @timer.should_receive(:format).and_return("Finished in 2.0 seconds")
    @tally.should_receive(:format).and_return("1 example, 1 failures")
    @formatter.instance_variable_set :@states, [@state]
    @formatter.finish
    @out.should == 
%[<ol>
<li><p>describe it ERROR</p>
<p>broken</p>
<pre>
path/to/some/file.rb:35:in method</pre>
</li>
</ol>
<p>Finished in 2.0 seconds</p>
<p class="fail">1 example, 1 failures</p>
</body>
</html>
]
  end
end
