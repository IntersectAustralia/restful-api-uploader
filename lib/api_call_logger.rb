require 'json'

class ApiCallLogger
  ENTRY_DELIMITER = '-------------------------------------------------------'
  attr_accessor :log_file

  def initialize(file_path)
    self.log_file = File.open(file_path, 'a')
  end

  def log_message(severity, message)
    time = timestamp
    output = "#{time}#{severity.ljust(6)}#{message}"
    puts output
    log_file.puts output
    log_file.flush
  end

  def log_general_error(message, exception)
    time = timestamp
    output = "#{time}WARN  #{message}\n#{exception.message}"
    puts output
    log_file.puts(output)
    log_file.flush
  end

  #no matching files?
  def log_group_error(config, exception)
    time = timestamp
    output = "#{time}WARN  File details #{config} #{exception.message}"
    puts output
    log_file.puts(output)
    log_file.flush
  end

  def log_start(file_path)
    time = timestamp
    output = "#{time}- attempting to upload file #{file_path}"
    puts output
    log_file.puts(output)
    log_file.flush
  end

  def log_request(params, url)
    time = timestamp
    puts "#{time}INFO  Transfering "

    log_file.printf time
    log_file.printf 'INFO  Transfering '
    params.each_pair do |k, v|
      if k == "file"
        puts("#{v.inspect} - #{number_to_human_size(v.size)}")
        log_file.puts("#{v.inspect} - #{number_to_human_size(v.size)}")
        log_file.flush
      end
    end
  end

  def log_response(response)
    time = timestamp

    output = ""

    if response.nil?
      output = "#{time}ERROR Client did not receive a response from server before timing out. Check server side to see if file was uploaded. "
      puts(output)
      log_file.puts(output)
      log_file.flush
    else
      #write an IF statement if 401 then error

      if response.status == 401
        output = "#{time}ERROR Response code: #{response.status} (UNAUTHORIZED), messages: [\"Invalid authentication token.\"]"
        puts(output)
        log_file.puts(output)
        log_file.flush
        return
      end

      output = "#{time}INFO  Response code: #{response.status} #{'(SUCCESS)' if response.status == 200}"
      puts output
      log_file.printf(output)

      response_details = JSON.parse(response.body)
      response_details.each_pair do |k, v|
        if k == "messages"
          puts(" #{k}: #{v.inspect}")
          log_file.puts(" #{k}: #{v.inspect}")
          log_file.flush
        end

      end
    end
  end

  #errors i.e. no file or directory, no url
  def log_error(exception)
    time = timestamp
    puts "#{time}ERROR "
    puts(exception.message)

    log_file.printf time
    log_file.printf('ERROR ')
    log_file.puts(exception.message)
    log_file.flush
  end

  def log_warning(exception)
    time = timestamp
    puts "#{time}WARN  "
    puts(exception.message)

    log_file.printf time
    log_file.printf('WARN  ')
    log_file.puts(exception.message)
    log_file.flush
  end

  def close
    log_file.puts ENTRY_DELIMITER
    log_file.close
  end

  def timestamp
    "#{Time.now} "
  end

  def number_to_human_size(size)
    case
      when size < 1024.0
        '%d Bytes' % size
      when size < 1024.0 * 1024.0
        '%.1f KB'  % (size / 1024.0)
      when size < 1024.0 * 1024.0 * 1024.0
        '%.1f MB'  % (size / (1024 * 1024.0))
      when size < 1024.0 * 1024.0 * 1024.0 * 1024.0
        '%.1f GB'  % (size / (1024.0 * 1024.0 * 1024.0))
      else
        '%.1f TB'  % (size / (1024.0 * 1024.0 * 1024.0 * 1024.0))
    end
  end

end
