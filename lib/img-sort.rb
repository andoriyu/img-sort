#!/usr/bin/env ruby 

require 'optparse' 
require 'ostruct'
require 'digest/md5'
require 'fileutils'
require 'rmagick'

class ImgSort
  attr_reader :options

  VERSION="0.1.0"

  def initialize(arguments = {})
    @arguments = arguments
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    @options.rename = true
    @options.hash_function = 'md5'
    # Init options parser
    @opt_parser = self.opts_parser
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? && arguments_valid?

      @start_date = Time.now
      puts "Start at #{@start_date}\n" if @options.verbose
      
      output_options if @options.verbose
            
      case sort!(@arguments[0], @arguments[1])
        when 1
          puts "Source directory doesn't exists!"
          exit 1
        when 2
          puts "Source directory is empty!"
          exit 2
      end

      @end_date = Time.now
      puts "Finished at #{@end_date}\n" if @options.verbose
      puts "Time wasted: #{Time.at(@end_date - @start_date).gmtime.strftime('%R:%S')}" unless @options.quite
      
    else
      output_usage
    end
      
  end
  
  protected
    def opts_parser 
      opts = OptionParser.new do |x|
        x.banner= "img-sort [options] <source dir> <dst dir>"
        x.on('-v', '--version', 'Show version')  { output_version ; exit 0 }
        x.on('-u', '--usage', 'Show usage')  { puts @opt_parser;  exit }
        x.on('-V', '--verbose', 'Be verbose')  { @options.verbose = true }  
        x.on('-q', '--quiet', 'Be quite')  { @options.quiet = true }
        x.on('-h', '--rename', 'Change file name to hash from that file (default)') {@options.rename = true}
        x.on('-n', '--no-rename', 'Save original name') {@options.rename = false}        
      end
      return opts
      
    end

  
    def parsed_options?
      @opt_parser.parse!(@arguments) rescue  puts "Argument error.\nArguments: #{@arguments.inspect}\n" ; return false 
      process_options
      true      
    end

    # Performs post-parse processing on options
    def process_options
      @options.verbose = false if @options.quiet
    end
    
    def output_options
      puts "Options:\n"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}\n"
      end
      puts "Arguments: #{@arguments.inspect}\n"
    end

    # True if required arguments were provided
    def arguments_valid?
      # TO DO - implement your real logic here
      true if (@arguments[0].is_a?(String) && @arguments[1].is_a?(String))
    end
    
    def output_help
      puts @opt_parser
      exit 0
    end
    
    def output_usage
     puts @opt_parser
     exit 1
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def sort!(from, to)
      @from = File.expand_path(from)
      @to = File.expand_path(to)
      return 1 unless Dir.exists?(@from)
      return 2 if Dir.entries(@from).count <= 2
      @files = Dir.glob("#{@from}/*.{png,jpg,jpeg,gif,tiff,bmp}")
      puts "Found #{@files.count} files" unless @options.quite     
      return 2 if @files.empty?
      FileUtils.mkdir @to unless Dir.exists?(@to)
      count =  0
      @total = @files.length
      @files.each do |file|
        count += 1
        img = Magick::Image::read(file).first
        wh_dir_name = img.columns.to_s + 'x' + img.rows.to_s
        FileUtils.mkdir "#{@to}/#{wh_dir_name}" unless Dir.exists?("#{@to}/#{wh_dir_name}")
        if @options.rename
          case @options.hash_function
            when "md5"
              digest = Digest::MD5.hexdigest(File.read(file))
            else
              return "11"
          end
          ext = File.extname(file)
          FileUtils.cp(file, "#{@to}/#{wh_dir_name}/#{digest}#{ext}")
        else
          FileUtils.cp(file, "#{@to}/#{wh_dir_name}/")
        end
        puts file + ' copied' if @options.verbose
      end
    end

end

