require File.expand_path(File.dirname(__FILE__) + '/api_call_logger')
require File.expand_path(File.dirname(__FILE__) + '/file_uploader')
require 'rest-client'
require 'yaml'

class BatchUploader

  attr_accessor :config, :log_writer, :log_file_path, :url, :common_params, :file_parameter_name, :file_uploader

  def initialize(config_path)
    self.log_file_path = File.join(File.dirname(__FILE__), '..', 'log', 'log.txt')
    self.log_writer = ApiCallLogger.new(log_file_path)

    begin
      self.config = YAML.load_file(config_path)
      self.url = config['api_endpoint']
      self.common_params = config['common_parameters']
      self.file_parameter_name = config['file_parameter_name']
      self.file_uploader = FileUploader.new(log_writer, file_parameter_name, url)
      raise "Supplied YML file did not contain an array named 'files'" unless config['files'].is_a?(Array)
    rescue => e
      log_writer.log_general_error('Error while loading configuration', e)
      log_writer.close
      raise e
    end

  end

  def run
    begin
      config['files'].each do |group|
        begin
          process_file_group(group)
        rescue => e
          log_writer.log_group_error(group, e)
        end
      end
    ensure
      log_writer.close
    end
  end


  def process_file_group(file_config)
    file_params = file_config['file_parameters']
    source_path = file_config['source_directory']
    file_pattern = file_config['file']
    transfer_to_path = file_config['transfer_to_directory']
    # make sure the source to path exists - this will raise an exception if it doesn't exist
    Dir.new(source_path)
    # make sure the transfer to path exists - this will raise an exception if it doesn't exist
    Dir.new(transfer_to_path)

    post_params = {}
    post_params.merge!(common_params)
    post_params.merge!(file_params)

    if file_pattern.is_a?(String)
      upload_file(source_path, file_pattern, post_params, transfer_to_path)
    elsif file_pattern.is_a?(Regexp)
      found_any = false
      Dir.foreach(source_path) do |file_name|
        if file_pattern =~ file_name
          upload_file(source_path, file_name, post_params, transfer_to_path)
          found_any = true
        end
      end
      raise "Did not find any files matching regular expression #{file_pattern}" unless found_any
    else
      raise "Unrecognised file name, must be a String or Regexp, found #{file_pattern.class}"
    end
  end

  def upload_file(source_path, file_name, post_params, transfer_to_path)
    begin
      file_path = File.join(source_path, file_name)
      log_writer.log_start(file_path)
      # make sure the file exists - this will raise an exception if it doesn't
      File.new(file_path)
      # make sure that the backup file doesn't exist
      dest_path = File.join(transfer_to_path, file_name)
      raise "Transfer to file already exists #{dest_path}" if File.exist?(dest_path)

      success = file_uploader.upload(file_path, post_params)
      if success
        FileUtils.mv File.new(file_path), dest_path
      end
    rescue
      log_writer.log_error($!)
    end
  end
end
