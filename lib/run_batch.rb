require File.expand_path(File.dirname(__FILE__) + '/batch_uploader')

config = ARGV[0]

if config.nil? || config.length == 0
  raise 'You need to pass an argument containing the full path of the config yaml file'
end

unless File.exist?(config)
  raise "Specified config file not found #{config}"
end

BatchUploader.new(config).run