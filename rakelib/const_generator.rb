require "tempfile"

class ConstGenerator
  class Constant
    attr_reader :name, :format, :cast
    attr_accessor :value

    def initialize(name, format, cast, converter=nil)
      @name = name
      @format = format
      @cast = cast
      @converter = converter
      @value = nil
    end
    
    def converted_value
      if @converter
        @converter.call(@value)
      else
        @value
      end
    end
  end  
    
  def initialize
    @includes = []
    @constants = {}
  end
  
  def get_const(name)
    return @constants[name].value
  end
  
  attr_reader :constants

  def include(i)
    @includes << i
  end

  def const(name, format="%d", cast="", &converter)
    const = Constant.new(name, format, cast, converter)
    @constants[name.to_s] = const
    return const
  end

  def calculate
    binary = "rb_const_gen_bin_#{Process.pid}"

    Tempfile.open("rbx_const_gen_tmp") do |f|
      f.puts "#include <stdio.h>"

      @includes.each do |inc|
        f.puts "#include <#{inc}>"
      end

      f.puts "#include <stddef.h>\n\n"
      f.puts "int main(int argc, char **argv)\n{"

      @constants.each_value do |const|
        f.puts <<EOF
  #ifdef #{const.name}
  printf("#{const.name} #{const.format}\\n", #{const.cast}#{const.name});
  #endif
EOF
      end

      f.puts "\n\treturn 0;\n}"
      f.flush
      
      `gcc -D_DARWIN_USE_64_BIT_INODE -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -x c -Wall #{f.path} -o #{binary}`
    end

    output = `./#{binary}`
    File.unlink(binary)

    output.each_line do |line|
      md = line.match(/^(\S+)\s+(.*)$/)
      const = @constants[md.captures.first]
      const.value = md.captures[1]
    end
  end
end
