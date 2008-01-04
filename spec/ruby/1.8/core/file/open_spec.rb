require File.dirname(__FILE__) + '/../../spec_helper'

describe "File.open" do 
  before :each do         
    @file = 'test.txt'    
    File.delete(@file) if File.exists?(@file)
    File.delete("fake") if File.exists?("fake")
    @fh = nil
    @fd = nil
    @flags = File::CREAT | File::TRUNC | File::WRONLY
    File.open(@file, "w"){} # touch
  end
  
  after :each do
    File.delete("fake") rescue nil
    @fh.delete if @fh  rescue nil
    @fh.close if @fh rescue nil
    @fh    = nil
    @fd    = nil
    @file  = nil
    @flags = nil
  end
  
  it "open the file (basic case)" do 
    @fh = File.open(@file) 
    @fh.class.should == File
    File.exists?(@file).should == true
  end

  it "open file when call with a block (basic case)" do
    File.open(@file){ |fh| @fd = fh.fileno }
    lambda { File.open(@fd) }.should raise_error(SystemCallError) # Should be closed by block
    File.exists?(@file).should == true
  end

  it "open with mode string" do
    @fh = File.open(@file, 'w') 
    @fh.class.should == File
    File.exists?(@file).should == true
  end

  it "open a file with mode string and block" do
    File.open(@file, 'w'){ |fh| @fd = fh.fileno }
    lambda { File.open(@fd) }.should raise_error(SystemCallError)
    File.exists?(@file).should == true
  end

  it "open a file with mode num" do 
    @fh = File.open(@file, @flags)
    @fh.class.should == File
    File.exists?(@file).should == true
  end

  it "open a file with mode num and block" do
    File.open(@file, 'w'){ |fh| @fd = fh.fileno }
    lambda { File.open(@fd) }.should raise_error(SystemCallError)
    File.exists?(@file).should == true
  end

  # For this test we delete the file first to reset the perms
  it "open the file when call with mode, num and permissions" do
    File.delete(@file)
    @fh = File.open(@file, @flags, 0755)
    File.stat(@file).mode.to_s(8).should == "100755"
    @fh.class.should == File
    File.exists?(@file).should == true
  end

  # For this test we delete the file first to reset the perms
  it "open the flie when call with mode, num, permissions and block" do
    File.delete(@file)
    File.open(@file, @flags, 0755){ |fh| @fd = fh.fileno }
    lambda { File.open(@fd) }.should raise_error(SystemCallError)
    File.stat(@file).mode.to_s(8).should == "100755"
    File.exists?(@file).should == true
  end

  it "open the file when call with fd" do
    @fh = File.open(@file)
    @fh = File.open(@fh.fileno) 
    @fh.class.should == File
    File.exists?(@file).should == true
  end

  # Note that this test invalidates the file descriptor in @fh. That's
  # handled in the teardown via the 'rescue nil'.
  #
  it "open a file with a file descriptor d and a block" do 
    @fh = File.open(@file) 
    File.open(@fh.fileno){ |fh| @fd = fh.fileno }
    lambda { File.open(@fd) }.should raise_error(SystemCallError)
    @fh.class.should == File
    File.exists?(@file).should == true
  end  
    
  it "open a file that no exists when use File::WRONLY mode" do 
    lambda { File.open("fake", File::WRONLY) }.should raise_error(Errno::ENOENT)
  end  
  
  it "open a file that no exists when use File::RDONLY mode" do 
    lambda { File.open("fake", File::RDONLY) }.should raise_error(Errno::ENOENT)
  end    
  
  it "open a file that no exists when use 'r' mode" do 
    lambda { File.open("fake", 'r') }.should raise_error(Errno::ENOENT)
  end  
  
  it "open a file that no exists when use File::EXCL mode" do 
    lambda { File.open("fake", File::EXCL) }.should raise_error(Errno::ENOENT)
  end  
  
  it "open a file that no exists when use File::NONBLOCK mode" do 
    lambda { File.open("fake", File::NONBLOCK) }.should raise_error(Errno::ENOENT)
  end  
  
  it "open a file that no exists when use File::TRUNC mode" do 
    lambda { File.open("fake", File::TRUNC) }.should raise_error(Errno::ENOENT)
  end  
  
  it "open a file that no exists when use File::NOCTTY mode" do 
    lambda { File.open("fake", File::NOCTTY) }.should raise_error(Errno::ENOENT)
  end  
  
  it "open a file that no exists when use File::CREAT mode" do 
    @fh = File.open("fake", File::CREAT)      
    @fh.class.should == File
    File.exists?(@file).should == true
  end  
  
  it "open a file that no exists when use 'a' mode" do 
    @fh = File.open("fake", 'a')      
    @fh.class.should == File
    File.exists?(@file).should == true
  end  
     
  it "open a file that no exists when use 'w' mode" do 
    @fh = File.open("fake", 'w')  
    @fh.class.should == File
    File.exists?(@file).should == true
  end  
  
  # Check the grants associated to the differents open modes combinations.   
  it "raise an ArgumentError exception when call with an unknown mode" do 
    lambda { File.open(@file, "q") }.should raise_error(ArgumentError)
  end
  
  it "can read in a block when call open with RDONLY mode" do 
    File.open(@file, File::RDONLY) do |f| 
      f.gets.should == nil
    end
  end
  
  it "can read in a block when call open with 'r' mode" do 
    File.open(@file, "r") do |f| 
      f.gets.should == nil
    end
  end
  
  it "raise an IO exception when write in a block opened with RDONLY mode" do 
    File.open(@file, File::RDONLY) do |f| 
      lambda { f.puts "writing ..." }.should raise_error(IOError)
    end
  end
  
  it "raise an IO exception when write in a block opened with 'r' mode" do 
    File.open(@file, "r") do |f| 
      lambda { f.puts "writing ..." }.should raise_error(IOError)
    end
  end
  
  it "can't write in a block when call open with File::WRONLY||File::RDONLY mode" do  
    File.open(@file, File::WRONLY|File::RDONLY ) do |f|  
      f.puts("writing").should == nil 
    end 
  end  
  
  it "can't read in a block when call open with File::WRONLY||File::RDONLY mode" do 
    lambda {
      File.open(@file, File::WRONLY|File::RDONLY ) do |f| 
        f.gets.should == nil       
      end
    }.should raise_error(IOError)
  end    
  
  it "can write in a block when call open with WRONLY mode" do 
    File.open(@file, File::WRONLY) do |f| 
      f.puts("writing").should == nil
    end
  end
  
  it "can write in a block when call open with 'w' mode" do 
    File.open(@file, "w") do |f| 
      f.puts("writing").should == nil
    end
  end
  
  it "raise an IO exception when read in a block opened with WRONLY mode" do 
    File.open(@file, File::WRONLY) do |f| 
      lambda { f.gets  }.should raise_error(IOError)
    end
  end
  
  it "raise an IO exception when read in a block opened with 'w' mode" do 
    File.open(@file, "w") do |f| 
      lambda { f.gets   }.should raise_error(IOError)
    end
  end
  
  it "raise an IO exception when read in a block opened with 'a' mode" do 
    File.open(@file, "a") do |f| 
      lambda { f.gets  }.should raise_error(IOError)
    end
  end
  
  it "raise an IO exception when read in a block opened with 'a' mode" do 
    File.open(@file, "a") do |f|        
      f.puts("writing").should == nil      
      lambda { f.gets }.should raise_error(IOError)
    end
  end  
  
  it "raise an IO exception when read in a block opened with 'a' mode" do 
    File.open(@file, File::WRONLY|File::APPEND ) do |f| 
      lambda { f.gets }.should raise_error(IOError)
    end
  end
  
  it "raise an IO exception when read in a block opened with File::WRONLY|File::APPEND mode" do 
    File.open(@file, File::WRONLY|File::APPEND ) do |f|        
      f.puts("writing").should == nil  
    end
  end
  
  it "raise an IO exception when read in a block opened with File::RDONLY|File::APPEND mode" do 
    lambda {
      File.open(@file, File::RDONLY|File::APPEND ) do |f|        
        f.puts("writing")  
      end
    }.should raise_error(Errno::EINVAL)
  end
  
  it "can read and write in a block when call open with RDWR mode" do 
    File.open(@file, File::RDWR) do |f| 
      f.gets.should == nil      
      f.puts("writing").should == nil
      f.rewind
      f.gets.should == "writing\n"
    end
  end  
  
  it "can't read in a block when call open with File::EXCL mode" do 
    lambda {
      File.open(@file, File::EXCL) do |f|  
        f.puts("writing").should == nil 
      end
    }.should raise_error(IOError)
  end
  
  it "can read in a block when call open with File::EXCL mode" do  
    File.open(@file, File::EXCL) do |f|  
      f.gets.should == nil      
    end 
  end    
    
  it "can read and write in a block when call open with File::RDWR|File::EXCL mode" do 
    File.open(@file, File::RDWR|File::EXCL) do |f| 
      f.gets.should == nil      
      f.puts("writing").should == nil
      f.rewind
      f.gets.should == "writing\n"
    end     
  end
  
  it "raise an Errorno::EEXIST if the file exists when open with File::CREAT|File::EXCL" do 
    lambda {
      File.open(@file, File::CREAT|File::EXCL) do |f|  
        f.puts("writing")
      end
    }.should raise_error(Errno::EEXIST)
  end
 
  it "create a new file when use File::WRONLY|File::APPEND mode" do 
    @fh = File.open(@file, File::WRONLY|File::APPEND) 
    @fh.class.should == File
    File.exists?(@file).should == true
  end  
  
  it "open a file when use File::WRONLY|File::APPEND mode" do 
    File.open(@file, File::WRONLY) do |f|
      f.puts("hello file")
    end    
    File.open(@file, File::RDWR|File::APPEND) do |f|
      f.puts("bye file") 
      f.rewind
      f.gets().should == "hello file\n"
      f.gets().should == "bye file\n"
      f.gets().should == nil
    end     
  end  
  
  it "raise an Errorno::EEXIST if the file exists when open with File::RDONLY|File::APPEND" do 
    lambda {
      File.open(@file, File::RDONLY|File::APPEND) do |f|  
        f.puts("writing").should == nil 
      end
    }.should raise_error(Errno::EINVAL)
  end
  
  it "create a new file when use File::TRUNC mode" do 
    # create and write in the file
    File.open(@file, File::RDWR) do |f|
      f.puts "hello file" 
    end    
    # Truncate the file    
    @fh = File.new(@file, File::TRUNC)   
    @fh.gets.should == nil
  end 
    
  
  it "can't read in a block when call open with File::TRUNC mode" do  
    File.open(@file, File::TRUNC) do |f|  
      f.gets  
    end 
  end
    
  it "open a file when use File::WRONLY|File::TRUNC mode" do 
    File.open(@file, File::WRONLY|File::TRUNC) 
    @fh.class.should == NilClass
    File.exists?(@file).should == true
  end
  
  it "can't write in a block when call open with File::TRUNC mode" do 
    lambda {
      File.open(@file, File::TRUNC) do |f|  
        f.puts("writing")
      end
    }.should raise_error(IOError)
  end  
      
  it "raise an Errorno::EEXIST if the file exists when open with File::RDONLY|File::TRUNC" do 
    lambda {
      File.open(@file, File::RDONLY|File::TRUNC) do |f|  
        f.puts("writing").should == nil 
      end
    }.should raise_error(IOError)
  end
  
  it "should throw Errno::EACCES when opening non-permitted file" do
    @fh = File.open(@file, "w")
    @fh.chmod(000)
    lambda { File.open(@file) }.should raise_error(Errno::EACCES)
  end
  
  it "should open a file for binary read" do
    @fh = File.open(@file, "rb")
  end
  
  it "should open a file for binary write" do
    @fh = File.open(@file, "wb")
  end
  
  it "should open a file for read-write and truncate the file" do
    @fh = File.open(@file, "w") { |f| f.puts("testing") } # Make sure the file is not empty 
    @fh = File.open(@file, "w+")    
    @fh.pos.should == 0
    @fh.eof?.should == true
    @fh.close
    File.size(@file).should == 0
  end

  it "should open a file for binary read-write starting at the beginning of the file" do
    @fh = File.open(@file, "w") { |f| f.puts("testing") } # Make sure the file is not empty 
    @fh = File.open(@file, "rb+")
    @fh.pos.should == 0
    @fh.eof?.should == false
  end
  
  it "should open a file for binary read-write and truncate the file" do
    @fh = File.open(@file, "w") { |f| f.puts("testing") } # Make sure the file is not empty 
    @fh = File.open(@file, "wb+")
    @fh.pos.should == 0
    @fh.eof?.should == true
    @fh.close
    File.size(@file).should == 0  
  end
   
  specify "expected errors " do
    lambda { File.open(true)  }.should raise_error(TypeError)
    lambda { File.open(false) }.should raise_error(TypeError)
    lambda { File.open(nil)   }.should raise_error(TypeError)
    lambda { File.open(-1)    }.should raise_error(SystemCallError) # kind_of ?
    lambda { File.open(@file, File::CREAT, 0755, 'test') }.should raise_error(ArgumentError)
    lambda { File.open(@file, 'fake') }.should raise_error(ArgumentError)
  end
end