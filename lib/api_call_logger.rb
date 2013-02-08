require 'json'

class ApiCallLogger
  ENTRY_DELIMITER = '-------------------------------------------------------'
  attr_accessor :log_file

  def initialize(file_path)
    self.log_file = File.open(file_path, 'a')
  end

  def log_general_error(message, exception)
    log_file.puts timestamp
    log_file.puts 'ERROR OCCURRED'
    log_file.puts(message)
    log_file.puts(exception.message)
    log_file.puts(exception.backtrace.join("\n"))
    log_file.puts ENTRY_DELIMITER
  end

  def log_group_error(config, exception)
    log_file.puts timestamp
    log_file.puts 'ERROR OCCURRED'
    log_file.puts "File details #{config}"
    log_file.puts(exception.message)
    log_file.puts(exception.backtrace.join("\n"))
    log_file.puts ENTRY_DELIMITER
  end

  def log_start(file_path)
    log_file.puts("#{Time.now} - attempting to upload file #{file_path}")
  end

  def log_request(params, url)
    log_file.puts timestamp
    log_file.puts("Endpoint: #{url}")
    log_file.puts('Parameters:')
    params.each_pair do |k, v|
      log_file.puts("    #{k}: #{v.inspect}")
    end
  end

  def log_response(response)
    log_file.puts timestamp
    if response.nil?
      log_file.puts('ERROR: client did not receive a response from server before timing out. Check server side to see if file was uploaded.')
    else
      log_file.puts("Response code: #{response.code} #{'(SUCCESS)' if response.code == 200}")
      log_file.puts('Response details:')
      response_details = JSON.parse(response.body)
      response_details.each_pair do |k, v|
        log_file.puts("    #{k}: #{v.inspect}")
      end
    end
    log_file.puts(ENTRY_DELIMITER)
  end

  def log_error(exception)
    log_file.puts timestamp
    log_file.puts('ERROR UPLOADING FILE')
    log_file.puts(exception.message)
    log_file.puts(exception.backtrace.join("\n"))
    log_file.puts(ENTRY_DELIMITER)
  end

  def close
    log_file.close
  end

  def timestamp
    "## TIMESTAMP: #{Time.now}"
  end


end
