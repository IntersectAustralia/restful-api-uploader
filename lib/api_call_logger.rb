require 'json'

class ApiCallLogger
  ENTRY_DELIMITER = '-------------------------------------------------------'

  attr_accessor :log_file

  def initialize(file_path)
    self.log_file = File.open(file_path, 'a')
  end

  def log_request(params, url)
    log_file.puts("Attempting API upload at #{Time.now}")
    log_file.puts("Endpoint: #{url}")
    log_file.puts('Parameters:')
    params.each_pair do |k, v|
      log_file.puts("    #{k}: #{v.inspect}")
    end
  end

  def log_response(response)
    log_file.puts('ERROR UPLOADING FILE') if response.code != 200
    log_file.puts("Response code: #{response.code}")
    log_file.puts('Response details:')
    response_details = JSON.parse(response.body)
    response_details.each_pair do |k, v|
      log_file.puts("    #{k}: #{v.inspect}")
    end
    log_file.puts(ENTRY_DELIMITER)
  end

  def log_error(exception)
    log_file.puts('UNEXPECTED ERROR UPLOADING FILE')
    log_file.puts(exception.message)
    log_file.puts(exception.backtrace.join("\n"))
    log_file.puts(ENTRY_DELIMITER)
  end

  def close
    log_file.close
  end

end