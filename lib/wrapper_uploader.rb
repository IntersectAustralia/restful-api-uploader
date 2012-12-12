require File.expand_path(File.dirname(__FILE__) + '/api_call_logger')
require 'rest-client'
require 'yaml'

class WrapperUploader

  attr_accessor :config
  attr_accessor :log_writer
  attr_accessor :log_file_path

  def initialize(config_path)
    self.config = YAML.load_file(config_path)
    self.log_file_path = File.join(File.dirname(__FILE__), '..', 'log', 'log.txt')
    self.log_writer = ApiCallLogger.new(log_file_path)
  end

  def run
    begin
      config['files'].each { |file_config| prepare_and_stage_file(file_config) }
    ensure
      log_writer.close
    end
  end

  def prepare_and_stage_file(file_config)
    begin
      src_path = file_config['path']
      backup_paths = file_config['destination']
      rotation = file_config['rotate']

      if backup_paths.nil? || backup_paths.empty? || src_path.nil? || src_path.empty?
        #config file cannot be interpreted.
        #raise ConfigurationException(config_path)
      end
      dest_path = backup_paths.first

      #Construct new file name based on rotation params
      rotation_date = get_rotation_date(rotation)
      filename = get_dated_filename(src_path, rotation_date)

      temp_destination = File.join(dest_path, filename)
      if File.exist?(temp_destination)
        raise TempFileExistsException.new(temp_destination)
      end
      if !rotation_date.nil? && rotation_date.eql?(Date.today)
        FileUtils.mv src_path, temp_destination
      else
        FileUtils.cp src_path, temp_destination
        backup_paths.each do |backup_path|
          backup_dest = File.join(backup_path, filename)
          unless temp_destination.eql?(backup_dest)
            FileUtils.cp temp_destination, backup_dest
          end
        end
      end

      #finished. invoker should now call transfer script.

    rescue TempFileExistsException => e
      log_writer.log_error(e)
    rescue RestClient::Exception => e
      log_writer.log_response(e.response)
    rescue
      log_writer.log_error($!)
    end
  end

  def get_rotation_date(rotation_type)
    unless rotation_type.nil?
      if rotation_type.eql?('daily')
        return Date.today
      elsif rotation_type.eql?('monthly')
        return  Date.civil(Date.today.year, Date.today.month, -1)
      elsif rotation_type.eql?('weekly')
        date  = Date.parse("Saturday")
        delta = date > Date.today ? 0 : 7

        return date + delta
      end
    end
  end

  def get_dated_filename(src_path, rotation_date)
    unless rotation_date.nil?
      date = rotation_date.strftime("%Y%m%d")
      existing_filename = src_path.split('/').last
      new_filename = existing_filename.split('.').first
      new_filename << "_#{date}"
      new_filename << ".#{src_path.split('.').last}"
    end
  end
end

class TempFileExistsException < RuntimeError
 def initialize(path)
    @path = path
  end

  def path
    @path
  end

  def ==(other)
    return false unless other.is_a?(TempFileExistsException)
    backup_path == other.backup_path
  end

  def message
    "File #{@path} already exists in upload queue. Upload of this file has been aborted."
  end
end

class ConfigurationException < RuntimeError
  def initialize(path)
    @path = path
  end

  def backup_path
    @path
  end

  def ==(other)
    return false unless other.is_a?(ConfigurationException)
    backup_path == other.backup_path
  end

  def message
    "yml configuration file #{@path} could not be interpreted. See user manual for a correct configuration example."
  end
end