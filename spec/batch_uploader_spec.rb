require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../lib/batch_uploader')

describe BatchUploader do
  let(:template_config_path) { File.expand_path(File.dirname(__FILE__) + '/resources/config.yml') }
  let(:spec_config_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/config.yml') }
  let(:sample1_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/weather_station.dat') }
  let(:sample2_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/sample1.txt') }

  before do
    # Update the YAML config with absolute paths - in a real deployment it must have absolute paths, here we need to
    # update it so that the tests can work on a local copy in any directory
    rewrite_paths(template_config_path, spec_config_path, [sample1_path, sample2_path])
    create_test_file(sample1_path)
    create_test_file(sample2_path)
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

    it 'should subsitute date placeholders in filenames' do
      today_dated_sample_path = File.expand_path(File.dirname(__FILE__) + '/../tmp/%%today_yyyy-mm-dd%%.txt')
      yesterday_dated_sample_path = File.expand_path(File.dirname(__FILE__) + '/../tmp/%%yesterday_yyyy-mm-dd%%.txt')

      expected_today_path = File.expand_path(File.dirname(__FILE__) + "/../tmp/#{Date.today.strftime('yyyy-mm-dd')}.txt")
      expected_yesterday_path = File.expand_path(File.dirname(__FILE__) + "/../tmp/#{(Date.today - 1).strftime('yyyy-mm-dd')}.txt")

      create_test_file(expected_today_path)
      create_test_file(expected_yesterday_path)

      rewrite_paths(template_config_path, spec_config_path, [today_dated_sample_path, yesterday_dated_sample_path])

      logger = stub('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)
      logger.stub(:log_request)
      logger.stub(:log_response)
      logger.stub(:close)

      RestClient.should_receive(:post) do |url, params, settings|
        params['file'].should be_a(File)
        params['file'].path.should eq(expected_today_path)
      end
      RestClient.should_receive(:post) do |url, params, settings|
        params['file'].should be_a(File)
        params['file'].path.should eq(expected_yesterday_path)
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

def rewrite_paths(template_path, output_path, files)
  buffer = YAML::load_file(template_path)
  files.each_with_index do |path, index|
    buffer['files'][index]['path'] = path
  end
  File.open(output_path, 'w+') { |f| f.write(YAML::dump(buffer)) }
end

def create_test_file(path)
  File.open(path, 'w+') { |f| f.write('some random text') }
end