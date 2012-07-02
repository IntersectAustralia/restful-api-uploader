require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../lib/batch_uploader')

describe BatchUploader do
  let(:template_config_path) { File.expand_path(File.dirname(__FILE__) + '/resources/config.yml') }
  let(:spec_config_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/config.yml') }
  let(:sample1_path) { File.expand_path(File.dirname(__FILE__) + '/resources/weather_station.dat') }
  let(:sample2_path) { File.expand_path(File.dirname(__FILE__) + '/resources/sample1.txt') }

  before do
    # Update the YAML config with absolute paths - in a real deployment it must have absolute paths, here we need to
    # update it so that the tests can work on a local copy in any directory
    buffer = YAML::load_file(template_config_path)
    buffer['files'][0]['path'] = sample1_path
    buffer['files'][1]['path'] = sample2_path
    File.open(spec_config_path, 'w+') { |f| f.write(YAML::dump(buffer)) }
  end

  describe 'Reading the config' do
    it 'should read the YAML configuration correctly' do
      uploader = BatchUploader.new(spec_config_path)
      uploader.config['api_endpoint'].should eq('http://localhost:3000/data_files/api_create')
    end
  end

  describe 'Sending files' do
    it 'should run through each file in the YAML config and send it to the API endpoint with the correct params' do
      logger = stub('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)
      logger.stub(:log_request)
      logger.stub(:log_response)
      logger.stub(:close)

      RestClient.should_receive(:post) do |url, params, settings|
        url.should eq('http://localhost:3000/data_files/api_create')
        settings.should eq({accept: :json})
        params.size.should eq(5)
        params['auth_token'].should eq('RfmknM43yYnZxtVPfAuH')
        params['experiment_id'].should eq(78)
        params['type'].should eq('RAW')
        params['description'].should eq('some desc')
        params['file'].should be_a(File)
        params['file'].path.should eq(sample1_path)
      end
      RestClient.should_receive(:post) do |url, params, settings|
        url.should eq('http://localhost:3000/data_files/api_create')
        settings.should eq({accept: :json})
        params.size.should eq(5)
        params['auth_token'].should eq('RfmknM43yYnZxtVPfAuH')
        params['experiment_id'].should eq('invalid')
        params['type'].should eq('PROCESSED')
        params['description'].should eq('another desc')
        params['file'].should be_a(File)
        params['file'].path.should eq(sample2_path)
      end
      uploader = BatchUploader.new(spec_config_path)
      uploader.run

    end

    it 'should pass the response to the logger' do
      logger = mock('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)

      response1 = mock('response1')
      response2 = mock('response2')
      RestClient.should_receive(:post).and_return(response1)
      RestClient.should_receive(:post).and_return(response2)

      logger.should_receive(:log_request).twice
      logger.should_receive(:log_response).with(response1)
      logger.should_receive(:log_response).with(response2)
      logger.should_receive(:close).once

      uploader = BatchUploader.new(spec_config_path)
      uploader.run
    end

    it 'should still pass the response to the logger when a rest client exception is raised' do
      logger = mock('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)

      response1 = mock('response1')
      response2 = mock('response2')
      RestClient.should_receive(:post).and_return(response1)
      RestClient.should_receive(:post).and_raise(RestClient::Exception.new(response2, 400))

      logger.should_receive(:log_request).twice
      logger.should_receive(:log_response).with(response1)
      logger.should_receive(:log_response).with(response2)
      logger.should_receive(:close).once

      uploader = BatchUploader.new(spec_config_path)
      uploader.run
    end

    it 'should log an error if some other type of exception is raised' do
      logger = mock('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)

      error = Errno::ECONNREFUSED.new #simulate connection refused
      response2 = mock('response2')
      RestClient.should_receive(:post).and_raise(error)
      RestClient.should_receive(:post).and_return(response2)

      logger.should_receive(:log_request).twice
      logger.should_receive(:log_error).with(error)
      logger.should_receive(:log_response).with(response2)
      logger.should_receive(:close).once

      uploader = BatchUploader.new(spec_config_path)
      uploader.run
    end
  end
end
