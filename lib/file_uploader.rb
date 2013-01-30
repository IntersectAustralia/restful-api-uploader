class FileUploader

  attr_accessor :log_writer, :file_parameter_name, :server_url

  def initialize(log_writer, file_parameter_name, server_url)
    self.log_writer = log_writer
    self.file_parameter_name = file_parameter_name
    self.server_url = server_url
  end

  def upload(file_path, post_params)
    file = File.new(file_path)
    post_params[file_parameter_name] = file
    perform_upload(post_params)
  end

  def perform_upload(post_params)
    begin
      log_writer.log_request(post_params, server_url)
      response = RestClient.post server_url, post_params, accept: :json
      log_writer.log_response(response)
      response.code == 200
    rescue RestClient::Exception => e
      log_writer.log_response(e.response)
      false
    rescue
      log_writer.log_error($!)
      false
    end
  end

end
