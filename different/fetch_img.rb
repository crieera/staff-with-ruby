require 'open-uri'
require 'fileutils'

def show_how_it_works
	if ARGV.length == 0
		puts "Cannot run script without any argument"
		puts "Use 'fetch_img.rb -h' for details of usage"
	elsif  ARGV.length > 0 && ARGV.length < 3
		case ARGV[0]
		when "-h"	#help
			puts "Use flag '-l' to add a URL with HTML page you want to look through and get all images from it"
			puts "Run 'ruby fetch_img.rb -l YOUR_URL'"
		when "-l"	#url
			check_flag = check_url ARGV[1]
			if ARGV[1] == nil || !check_flag
				puts "No url or it is invalid"
			elsif check_flag
				links_array = fetch(ARGV[1])
				download(links_array)
				puts "\nDone!"
			end
		else
			puts "Wrong flag argument"
		end
	else
		puts "Wrong number of arguments"
	end
end

def check_url(url)
	pattern = /^https?\:\/\/[-a-z0-9.]{1,}\.[a-z]{2,}((\/([-_A-Za-z0-9]){1,}){1,})?/
	pattern.match? url
end

def fetch(url)
	begin
		arr = []
		img_link = /src=\"(http(s)?\:\/\/[-a-z0-9.]{1,}\.[a-z]{2,}(\/([-_A-Za-z0-9]){1,}){1,}\.(png|jpg|jpeg))\"/
		page_content = open(url,{ssl_verify_mode: 0}).read
		page_content.each_line do |line|
			matches = img_link.match(line)
			arr << matches[1] if matches
		end
		return arr
	rescue Exception => e
		puts e
	end
end

def create_directory()
	begin
		FileUtils::mkdir_p 'loaded_images/'
	rescue Exception => e
		print e
	end
end

def download(images_array)
	begin
		if create_directory
			loading_path = "loaded_images/"
		else
			loading_path = ""
		end
		file_count = -1
		images_array.each do |img_link|
			image_extension = /.(png|jpg|jpeg)/.match(img_link)
			File.write("#{loading_path + 'image'}#{file_count+=1}#{'.' + image_extension[1]}", open(img_link).read)
			print "File #{file_count} downloaded\r"
		end
	rescue Exception => e
		print e
	end
end


show_how_it_works
