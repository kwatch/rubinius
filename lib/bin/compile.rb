class ExtensionCompiler
  
  def initialize(file, extra="")
    @includes = []
    @extra = extra
    @input = file
    @options = "-g"
    calculate_output()
  end
  
  attr_reader :output
  
  def calculate_output
    m = /(.*)\.[^\.]+/.match(@input)
    if m
      @output = "#{m[1]}.#{Rubinius::LIBSUFFIX}"
    else
      @output = "#{@input}.#{Rubinius::LIBSUFFIX}"
    end
  end
    
  def windows?
    Rubinius::OS == :win32
  end
  
  def gcc?
    Rubinius::COMPILER == :gcc
  end
  
  def vcc?
    Rubinius::OS == :win32 and Rubinius::COMPILER == :microsoft
  end
  
  def mingw?
    Rubinius::OS == :win32 and Rubinius::COMPILER == :gcc  
  end
  
  def cygwin?
    Rubinius::OS == :cygwin
  end
  
  def darwin?
    Rubinius::OS == :darwin
  end
  
  def global_options
    str = @options.dup
    @includes.each do |inc|
      str << " -I##{inc}"
    end
    
    if File.exists?("shotgun/lib/subtend/ruby.h")
      str << " -Ishotgun/lib/subtend"
    end
    str
  end
  
  def compiler
    if ENV['CC']
      return ENV['CC']
    end
    
    Rubinius::COMPILER_PATH
  end
    
  # Adapted from RubyInline
  def link_options
    if vcc?
      "-link /LIBPATH:\"#{@libdir}\" /DEFAULTLIB:\"#{@lib}\" /INCREMENTAL:no /EXPORT:#{@init}"
    elsif mingw?
      "-Wl,--enable-auto-import -L#{@libdir}"
    elsif cygwin?
      "-L/usr/local/lib"
    elsif darwin?
      "-dynamic -bundle -undefined suppress -flat_namespace"
    else
      "-shared"
    end
  end
  
  def compile
    cmd = "#{compiler} #{global_options} #{link_options} #{@input} -o #{@output} #{@extra}"
    puts cmd if $VERBOSE
    system cmd
  end
end

file = ARGV.shift

if file.suffix?(".c")
  puts "Compiling extension #{file}..."
  ext = ExtensionCompiler.new(file, ARGV.join(" "))
  ext.compile
  if File.exists?(ext.output)
    puts "Created #{ext.output}"
  else
    puts "Unable to compile extension into #{ext.output}. Check compiler log."
    exit 1
  end
else
  if File.exists?(file)
    puts "Compiling #{file}..."
    compile(file)
  else
    puts "Unable to compile '#{file}'"
  end
end