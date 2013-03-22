require 'json'

class ApiCallLogger
  ENTRY_DELIMITER = '-------------------------------------------------------'
  attr_accessor :log_file

  def initialize(file_path)
    self.log_file = File.open(file_path, 'a')
  end

  def log_message(severity, message)
    log_file.printf timestamp
    log_file.printf 'ERROR ' if severity == 'ERROR'
    log_file.printf 'INFO  ' if severity == 'INFO'
    log_file.printf 'WARN  ' if severity == 'WARN'
    log_file.printf '' if severity == 'SYM'
    log_file.puts message
  end

  def log_general_error(message, exception)
    log_file.printf timestamp
    log_file.printf 'WARN  '
    log_file.printf(message)
    log_file.puts(exception.message)
    #log_file.puts(exception.backtrace.join("\n"))
    #log_file.puts ENTRY_DELIMITER
  end

  #no matching files?
  def log_group_error(config, exception)
    log_file.printf timestamp
    log_file.printf 'WARN  '
    log_file.printf "File details #{config} "
    log_file.puts(exception.message)
    #log_file.puts(exception.backtrace.join("\n"))
    #log_file.puts ENTRY_DELIMITER
  end

  def log_start(file_path)
    log_file.puts("#{Time.now} - attempting to upload file #{file_path}")
  end

  def log_request(params, url)
    log_file.printf timestamp
    log_file.printf 'INFO  Transfering '
    #log_file.printf("Endpoint: #{url} \n")
    #log_file.puts('Parameters:')
    params.each_pair do |k, v|
      #log_file.puts("    #{k}: #{v.inspect}")
      if k == "file"
        log_file.puts("#{v.inspect}")
      end
    end
  end

  def log_response(response)
    log_file.printf timestamp
    if response.nil?
      log_file.puts('ERROR Client did not receive a response from server before timing out. Check server side to see if file was uploaded. ')
    else
      #write an IF statement if 401 then error

      if response.code == 401
        log_file.puts("ERROR Response code: #{response.code} (UNAUTHORIZED), messages: [\"Invalid authentication token.\"]")
        return
      end

      log_file.printf("INFO  Response code: #{response.code} ")
      log_file.printf("#{'(SUCCESS)' if response.code == 200}")

      response_details = JSON.parse(response.body)
      response_details.each_pair do |k, v|
        #log_file.puts("#{k}: #{v.inspect}")
        if k == "messages"
          log_file.puts(" #{k}: #{v.inspect}")
        end

      end
    end
    #log_file.puts(ENTRY_DELIMITER)
  end

  #errors i.e. no file or directory, no url
  def log_error(exception)
    log_file.printf timestamp
    log_file.printf('ERROR ')
    log_file.puts(exception.message)
    #log_file.puts(exception.backtrace.join("\n"))
    #log_file.puts(ENTRY_DELIMITER)
  end

  def log_warning(exception)
    log_file.printf timestamp
    log_file.printf('WARN  ')
    log_file.puts(exception.message)

  end

  def close
    log_file.puts ENTRY_DELIMITER
    log_file.close
  end

  def timestamp
    "#{Time.now} "
  end


end