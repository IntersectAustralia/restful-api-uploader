require File.expand_path(File.dirname(__FILE__) + '/api_call_logger')
require 'rest-client'
require 'yaml'

class BatchUploader

  TODAY_LONG_FORMAT = '%%today_yyyy-mm-dd%%'
  YESTERDAY_LONG_FORMAT = '%%yesterday_yyyy-mm-dd%%'
  TODAY_SHORT_FORMAT = '%%today_yymmdd%%'
  YESTERDAY_SHORT_FORMAT = '%%yesterday_yymmdd%%'

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
      config['files'].each { |file_config| upload_file(file_config) }
    ensure
      log_writer.close
    end
  end

  def upload_file(file_config)
    begin
      url = config['api_endpoint']
      params = config['common_parameters']
      params.merge!(file_config['file_parameters'])

      input_file_path = file_config['path']
      backup_path = file_config['file_parameters']['backup']
      perform_backup = !backup_path.nil? && !backup_path.empty?

      file_to_upload_path = do_substitutions(input_file_path)
      file_to_upload_path = do_backup(input_file_path, backup_path) if perform_backup
      file = File.new(file_to_upload_path)

      params['file'] = file

      log_writer.log_request(params, url)
      response = RestClient.post url, params, accept: :json
      log_writer.log_response(response)
      # remove the original if the upload succeeded
      FileUtils.rm input_file_path if perform_backup
    rescue RestClient::Exception => e
      log_writer.log_response(e.response)
      # remove the backup if we failed to upload the file
      FileUtils.rm file_to_upload_path if perform_backup
    rescue
      log_writer.log_error($!)
      # remove the backup if we failed to upload the file
      FileUtils.rm file_to_upload_path if perform_backup
    end
  end

  def do_backup(input_file_path, backup_path)
    file_extension = File.extname(input_file_path)
    basename = File.basename(input_file_path, file_extension)

    move_to = File.join(backup_path, "#{basename}_#{Date.today.strftime("%Y-%m-%d")}#{file_extension}")

    FileUtils.cp input_file_path, move_to
    move_to
  end

  def do_substitutions(path)
    # Currently we support simple date substitutions, to cater for dated files. More can be added here if needed
    path.gsub!(TODAY_LONG_FORMAT, Date.today.strftime('%Y-%m-%d'))
    path.gsub!(YESTERDAY_LONG_FORMAT, (Date.today - 1).strftime('%Y-%m-%d'))
    path.gsub!(TODAY_SHORT_FORMAT, Date.today.strftime('%y%m%d'))
    path.gsub!(YESTERDAY_SHORT_FORMAT, (Date.today - 1).strftime('%y%m%d'))
    path
  end
end
