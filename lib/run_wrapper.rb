require File.expand_path(File.dirname(__FILE__) + '/wrapper_uploader')
require File.expand_path(File.dirname(__FILE__) + '/batch_uploader')

wrapper_config = ARGV[0]
transfer_config = ARGV[1]

#check for invalid arguments or no configuration file(s)
raise 'You need to pass an argument containing the full path of the wrapper config yaml file' if (wrapper_config.nil? || wrapper_config.length == 0)
raise 'You need to pass an argument containing the full path of the transfer config yaml file' if (transfer_config.nil? || transfer_config.length == 0)
raise "Specified wrapper config file not found #{wrapper_config}" unless File.exist?(wrapper_config)
raise "Specified config file not found #{transfer_config}" unless File.exist?(transfer_config)

#run transfer first (to clean up old errors)
batch_uploader = BatchUploader.new(transfer_config) 
batch_uploader.run(true)
puts "step 1: Batch completed. Check results in #{File.absolute_path(batch_uploader.log_file_path)}"

#then run wrapper for new uploads
wrapper_uploader = WrapperUploader.new(wrapper_config)
wrapper_uploader.run
puts "step 2: Upload wrapper has completed. Check results in #{File.absolute_path(wrapper_uploader.log_file_path)}"
puts "Now calling Upload Transcript"
puts "-------------"

#run transfer again for new uploads
batch_uploader = BatchUploader.new(transfer_config) 
batch_uploader.run(false)
puts "step 3: Batch completed. Check results in #{File.absolute_path(batch_uploader.log_file_path)}"
puts "upload script has finished."
