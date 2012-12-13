require File.expand_path(File.dirname(__FILE__) + '/wrapper_uploader')
require File.expand_path(File.dirname(__FILE__) + '/batch_uploader')

wrapper_config = ARGV[0]
transfer_config = ARGV[1]

if wrapper_config.nil? || wrapper_config.length == 0
  raise 'You need to pass an argument containing the full path of the wrapper config yaml file'
end

unless File.exist?(wrapper_config)
  raise "Specified wrapper config file not found #{wrapper_config}"
end

wrapper_uploader = WrapperUploader.new(wrapper_config)
wrapper_uploader.run

puts "Upload wrapper has completed. Check results in #{File.absolute_path(wrapper_uploader.log_file_path)}"
puts "Now calling Upload Transcript"
puts "-------------"


if transfer_config.nil? || transfer_config.length == 0
  raise 'You need to pass an argument containing the full path of the config yaml file'
end

unless File.exist?(transfer_config)
  raise "Specified config file not found #{transfer_config}"
end

batch_uploader = BatchUploader.new(transfer_config) 
batch_uploader.run

puts "Batch completed. Check results in #{File.absolute_path(batch_uploader.log_file_path)}"
