class FileSearcher
  attr_reader :options

  def initialize(options = {})
    @options = options    
    @files = []
  end

  def run

    load_all_files

    @options.each do |key, value|
      change_files_with key, value
    end

    show_files
  end

  private

    def load_all_files
      Find.find(ENV["HOME"]) do |path|
        if FileTest.directory?(path)
          File.basename(path)[0] == ?. ? Find.prune : next
        else
          @files << { filename: File.basename(path), directory: path }
        end
      end
    end

    def change_files_with(key, value)
      case key
      when :filename
        find_by value
      when :directory
        find_in_directory value
      when :extension
        find_with_extension value
      when :directory_to_copy
        copy_to value
      when :all_files
        filter_by value
      else
        report_about_nothing key, value
      end 
    end

    def find_by(filename)
      @files = @files.select { |file_group| file_group[:filename] == filename }
    end

    def find_in_directory(path)
      @files = @files.select { |file_group| file_group[:directory] == path }
    end

    def find_with_extension(extension)
      @files = @files.select { |file_group| file_group[:filename].split(".")[-1] == extension }
    end

    def copy_to(destination_path)
      @files.each do |file_group|
        begin
          FileUtils.mkdir_p destination_path
          FileUtils.cp file_group[:directory], destination_path
          puts "File #{file_group[:filename]} was copied to temp_path"
        rescue Exception => exc
          puts %{
            #{exc.message}. Not able to copy #{file_group[:directory]} to #{destination_path}.\n
            Will try to save it to temp directory....\n
          }
          begin
            temp_path = "temp-#{DateTime.now.strftime('%Q')}"
            dir_created = FileUtils.mkdir temp_path
            file_copied = FileUtils.cp(file_group[:filename], temp_path) if dir_created
            print file_copied
            puts
            puts "File #{file_group[:filename]} was copied to #{temp_path}" if file_copied
          rescue Exception => e
            puts "#{e.message}. Not able to create temp directory and copy file there"
            exit 1
          end
        end
      end
    end

    def filter_by(type)
      if type == 'not hidden'
        @files = @files.select { |file_group| file_group[:filename][0] != '.' }
      elsif type == 'hidden'
        @files = @files.select { |file_group| file_group[:filename][0] == '.' }
      end
    end

    def report_about_nothing(key, value)
      puts "There is nothing with your #{key} and #{value}. Please try again"
    end

    def show_files
      @files.each do |file_group|
        puts "File: #{file_group[:filename]}, at: #{file_group[:directory]}"
      end
    end
end

if __FILE__ == $0
  require 'optparse'
  require 'find'
  require 'fileutils'
  require 'date'

  options = {}

  parser = OptionParser.new do |opt|
    script_name = File.basename($0)

    opt.on('-f', '--filename filename') do |file|
      options[:filename] = file
    end

    opt.on('-d', '--directory directory') do |dir|
      options[:directory] = dir
    end

    opt.on('-e', '--extension extension') do |ext|
      options[:extension] = ext
    end

    opt.on('-c', '--copy-to destination_path') do |cpdir|
      options[:directory_to_copy] = cpdir
    end

    options[:all_files] = 'all'

    opt.on('--no-hidden') do
      options[:all_files] = 'not hidden'
    end

    opt.on('--only-hidden') do
      options[:all_files] = 'hidden'
    end

    opt.on('--all') do
      options[:all_files] = 'all'
    end

    opt.on_tail('-h', '--help') do
      puts 'Simple script that helps to find specified files in all directories in home'
      puts %{
          Usage: #{script_name} [OPTIONS]\n
          Example: #{script_name} -f FILENAME -e EXTENSION\n
          Options:\n
          \t-h, --help -->> for help with script usage\n
          \t-f, --file -->> search file with specified full name (with extension)\n
          \t-d, --directory -->> search file in specified directory\n
          \t-e, --extension -->> search files with specified extension\n
          \t-c, --copy-to -->> copy all found files to specified directory\n
          \t    --no-hidden --> list or search files without hidden files\n
          \t    --only-hidden -->> list or search only hidden files\n
          \t    --all --> list or search all files (not specified, default)\n
        }
      exit 0
    end
  end

  parser.parse!

  begin
    raise 'Option for file is missing' if (ARGV.include?('-f') || ARGV.include?('--file')) && !options.key?(:file)
    raise 'Option for target directory is missing' if (ARGV.include?('-d') || ARGV.include?('--directory')) && !options.key?(:directory)
    raise 'Option for file extension is missing' if (ARGV.include?('-e') || ARGV.include?('--e')) && !options.key?(:extension)
    raise 'Option for target directory to copy is missing' if (ARGV.include?('-c') || ARGV.include?('--copy-to')) && !options.key?(:directory_to_copy)
  rescue Exception => exc
    puts "Something wrong.\n #{exc.message}. Please use -h or --help for right usage"
    exit 1
  end

  start_time = Integer(DateTime.now.strftime('%Q'))
  FileSearcher.new(options).run
  end_time = Integer(DateTime.now.strftime('%Q'))

  puts "The operation was performed in #{end_time - start_time} milisec"
end