require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../lib/batch_uploader')

describe BatchUploader do

  let(:sample1_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/weather_station_01.dat') }
  let(:sample2_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/weather_station_02.dat') }
  let(:sample3_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/aweather_station_02.dat') }
  let(:sample4_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/sample1.txt') }
  let(:config_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/config.yml') }
  let(:source_files_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp') }
  let(:transfer_to_path) { File.expand_path(File.dirname(__FILE__) + '/../tmp/transfer_to') }
  let(:transfer_to_path_2) { File.expand_path(File.dirname(__FILE__) + '/../tmp/different') }

  before(:each) do
    create_test_file(sample1_path)
    create_test_file(sample2_path)
    create_test_file(sample3_path)
    create_test_file(sample4_path)

    FileUtils.mkdir(transfer_to_path) unless Dir.exist?(transfer_to_path)
    FileUtils.mkdir(transfer_to_path_2) unless Dir.exist?(transfer_to_path_2)
  end

  after(:each) do
    FileUtils.rm_r(transfer_to_path)
    FileUtils.rm_r(transfer_to_path_2)
  end

  describe 'Read config' do
    #TODO: should we check basic parameters are solid?
  end

  describe 'Validating each file group config' do
    it 'should abort the group and log an error if source path does not exist' do
      yml =
          "" "
        api_endpoint: http://localhost:3000/data_files/api_create
        common_parameters:
          auth_token: 1QpgMVLEkuopbzU4Jwq1
        file_parameter_name: file

        files:
          -
            source_directory: /I/dont/exist
            file: !ruby/regexp /\\Aweather_station_\\d{2}.dat\\z/
            transfer_to_directory: #{transfer_to_path}
            file_parameters:
              type: UNKNOWN
              org_level2_id: 78
              tag_names: 'Photo,Video'
          -
            source_directory: #{source_files_path}
            file: sample1.txt
            transfer_to_directory: #{transfer_to_path_2}
            file_parameters:
              type: RAW
              org_level2_id: 79

        " ""
      write_yml(yml, config_path)

      logger = stub('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)
      logger.stub(:log_start)
      logger.stub(:log_request)
      logger.stub(:log_response)
      logger.stub(:close)
      logger.should_receive(:log_group_error) do |group, ex|
        ex.message.should eq("No such file or directory - /I/dont/exist")
      end

      uploader = stub('mock uploader')
      FileUploader.stub(:new).and_return(uploader)
      expected_post_params4 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                               'type' => 'RAW',
                               'org_level2_id' => 79}
      uploader.should_receive(:upload).with(sample4_path, expected_post_params4)

      uploader = BatchUploader.new(config_path)
      uploader.run

    end
    it 'should abort and log an error if transfer to path does not exist' do
      yml =
          "" "
        api_endpoint: http://localhost:3000/data_files/api_create
        common_parameters:
          auth_token: 1QpgMVLEkuopbzU4Jwq1
        file_parameter_name: file

        files:
          -
            source_directory: #{source_files_path}
            file: !ruby/regexp /\\Aweather_station_\\d{2}.dat\\z/
            transfer_to_directory: /I/dont/exist
            file_parameters:
              type: UNKNOWN
              org_level2_id: 78
              tag_names: 'Photo,Video'
          -
            source_directory: #{source_files_path}
            file: sample1.txt
            transfer_to_directory: #{transfer_to_path_2}
            file_parameters:
              type: RAW
              org_level2_id: 79

        " ""
      write_yml(yml, config_path)

      logger = stub('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)
      logger.stub(:log_start)
      logger.stub(:log_request)
      logger.stub(:log_response)
      logger.stub(:close)
      logger.should_receive(:log_group_error) do |group, ex|
        ex.message.should eq("No such file or directory - /I/dont/exist")
      end

      uploader = stub('mock uploader')
      FileUploader.stub(:new).and_return(uploader)
      expected_post_params4 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                               'type' => 'RAW',
                               'org_level2_id' => 79}
      uploader.should_receive(:upload).with(sample4_path, expected_post_params4)

      uploader = BatchUploader.new(config_path)
      uploader.run

    end
    it 'should abort and log an error if single filename (string) does not exist' do
      yml =
          "" "
        api_endpoint: http://localhost:3000/data_files/api_create
        common_parameters:
          auth_token: 1QpgMVLEkuopbzU4Jwq1
        file_parameter_name: file

        files:
          -
            source_directory: #{source_files_path}
            file: !ruby/regexp /\\Aweather_station_\\d{2}.dat\\z/
            transfer_to_directory: #{transfer_to_path}
            file_parameters:
              type: UNKNOWN
              org_level2_id: 78
              tag_names: 'Photo,Video'
          -
            source_directory: #{source_files_path}
            file: nonexistent.txt
            transfer_to_directory: #{transfer_to_path_2}
            file_parameters:
              type: RAW
              org_level2_id: 79

        " ""
      write_yml(yml, config_path)

      logger = stub('mock logger')
      ApiCallLogger.stub(:new).and_return(logger)
      logger.stub(:log_start)
      logger.stub(:log_request)
      logger.stub(:log_response)
      logger.stub(:close)
      logger.should_receive(:log_error) do |ex|
        ex.message.should eq("No such file or directory - #{source_files_path}/nonexistent.txt")
      end

      uploader = stub('mock uploader')
      FileUploader.stub(:new).and_return(uploader)
      expected_post_params1 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                               'type' => 'UNKNOWN',
                               'org_level2_id' => 78,
                               'tag_names' => "Photo,Video"}
      uploader.should_receive(:upload).with(sample1_path, expected_post_params1)
      uploader.should_receive(:upload).with(sample2_path, expected_post_params1)

      uploader = BatchUploader.new(config_path)
      uploader.run
    end
    it 'should abort and log an error if no files match the regex' do
      pending
    end
    it 'should abort and log an error if the regex is badly formed' do
      pending
    end
    describe 'should abort and log an error if the file already exists in the transfer_to directory' do
      it 'should work for a single file' do
        yml =
            "" "
          api_endpoint: http://localhost:3000/data_files/api_create
          common_parameters:
            auth_token: 1QpgMVLEkuopbzU4Jwq1
          file_parameter_name: file

          files:
            -
              source_directory: #{source_files_path}
              file: !ruby/regexp /\\Aweather_station_\\d{2}.dat\\z/
              transfer_to_directory: #{transfer_to_path}
              file_parameters:
                type: UNKNOWN
                org_level2_id: 78
                tag_names: 'Photo,Video'
            -
              source_directory: #{source_files_path}
              file: sample1.txt
              transfer_to_directory: #{transfer_to_path_2}
              file_parameters:
                type: RAW
                org_level2_id: 79

          " ""
        write_yml(yml, config_path)
        uploader = stub('mock uploader')
        FileUploader.stub(:new).and_return(uploader)
        logger = stub('mock logger')
        ApiCallLogger.stub(:new).and_return(logger)
        logger.stub(:log_start)
        logger.stub(:log_request)
        logger.stub(:log_response)
        logger.stub(:close)
        logger.should_receive(:log_error) do |ex|
          ex.message.should eq("Transfer to file already exists #{transfer_to_path_2}/sample1.txt")
        end

        create_test_file(File.join(transfer_to_path_2, 'sample1.txt'))
        expected_post_params1 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                                 'type' => 'UNKNOWN',
                                 'org_level2_id' => 78,
                                 'tag_names' => "Photo,Video"}
        uploader.should_receive(:upload).with(sample1_path, expected_post_params1)
        uploader.should_receive(:upload).with(sample2_path, expected_post_params1)

        uploader = BatchUploader.new(config_path)
        uploader.run

      end

      it 'should work for a file in a matched set from a regex - and should continue with other files in set' do
        yml =
            "" "
          api_endpoint: http://localhost:3000/data_files/api_create
          common_parameters:
            auth_token: 1QpgMVLEkuopbzU4Jwq1
          file_parameter_name: file

          files:
            -
              source_directory: #{source_files_path}
              file: !ruby/regexp /\\Aweather_station_\\d{2}.dat\\z/
              transfer_to_directory: #{transfer_to_path}
              file_parameters:
                type: UNKNOWN
                org_level2_id: 78
                tag_names: 'Photo,Video'
            -
              source_directory: #{source_files_path}
              file: sample1.txt
              transfer_to_directory: #{transfer_to_path_2}
              file_parameters:
                type: RAW
                org_level2_id: 79

          " ""
        write_yml(yml, config_path)
        uploader = stub('mock uploader')
        FileUploader.stub(:new).and_return(uploader)
        logger = stub('mock logger')
        ApiCallLogger.stub(:new).and_return(logger)
        logger.stub(:log_start)
        logger.stub(:log_request)
        logger.stub(:log_response)
        logger.stub(:close)
        logger.should_receive(:log_error) do |ex|
          ex.message.should eq("Transfer to file already exists #{transfer_to_path}/weather_station_01.dat")
        end

        create_test_file(File.join(transfer_to_path, 'weather_station_01.dat'))
        expected_post_params1 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                                 'type' => 'UNKNOWN',
                                 'org_level2_id' => 78,
                                 'tag_names' => "Photo,Video"}
        expected_post_params4 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                                 'type' => 'RAW',
                                 'org_level2_id' => 79}
        uploader.should_receive(:upload).with(sample2_path, expected_post_params1)
        uploader.should_receive(:upload).with(sample4_path, expected_post_params4)

        uploader = BatchUploader.new(config_path)
        uploader.run

      end
    end
  end

  describe 'Performing the upload' do
    before(:each) do
      yml =
          "" "
        api_endpoint: http://localhost:3000/data_files/api_create
        common_parameters:
          auth_token: 1QpgMVLEkuopbzU4Jwq1
        file_parameter_name: file

        files:
          -
            source_directory: #{source_files_path}
            file: !ruby/regexp /\\Aweather_station_\\d{2}.dat\\z/
            transfer_to_directory: #{transfer_to_path}
            file_parameters:
              type: UNKNOWN
              org_level2_id: 78
              tag_names: 'Photo,Video'
          -
            source_directory: #{source_files_path}
            file: sample1.txt
            transfer_to_directory: #{transfer_to_path_2}
            file_parameters:
              type: RAW
              org_level2_id: 79

        " ""
      write_yml(yml, config_path)
    end

    describe 'Identifying the right files' do
      it 'should match the correct files based on both plain filenames and regexen' do
        uploader = stub('mock uploader')
        FileUploader.stub(:new).and_return(uploader)

        expected_post_params1 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                                 'type' => 'UNKNOWN',
                                 'org_level2_id' => 78,
                                 'tag_names' => "Photo,Video"}
        expected_post_params4 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                                 'type' => 'RAW',
                                 'org_level2_id' => 79}
        uploader.should_receive(:upload).with(sample1_path, expected_post_params1)
        uploader.should_receive(:upload).with(sample2_path, expected_post_params1)
        uploader.should_receive(:upload).with(sample4_path, expected_post_params4)

        uploader = BatchUploader.new(config_path)
        uploader.run
      end
    end
    describe 'moving the file to the transfer to directory on success' do
      it 'should move the files to the specified transfer_to directory' do
        uploader = stub('mock uploader')
        FileUploader.stub(:new).and_return(uploader)

        uploader.should_receive(:upload).and_return(true)
        uploader.should_receive(:upload).and_return(true)
        uploader.should_receive(:upload).and_return(true)

        uploader = BatchUploader.new(config_path)
        uploader.run

        File.exist?(sample1_path).should be_false
        File.exist?(sample2_path).should be_false
        File.exist?(sample4_path).should be_false

        File.exist?(File.join(transfer_to_path, 'weather_station_01.dat')).should be_true
        File.exist?(File.join(transfer_to_path, 'weather_station_02.dat')).should be_true
        File.exist?(File.join(transfer_to_path_2, 'sample1.txt')).should be_true
      end
    end
    describe 'leaving the files in place on failure' do
      it 'should leave the file alone on failure' do
        uploader = stub('mock uploader')
        FileUploader.stub(:new).and_return(uploader)

        expected_post_params1 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                                 'type' => 'UNKNOWN',
                                 'org_level2_id' => 78,
                                 'tag_names' => "Photo,Video"}
        expected_post_params4 = {'auth_token' => '1QpgMVLEkuopbzU4Jwq1',
                                 'type' => 'RAW',
                                 'org_level2_id' => 79}
        uploader.should_receive(:upload).with(sample1_path, expected_post_params1).and_return(false)
        uploader.should_receive(:upload).with(sample2_path, expected_post_params1).and_return(true)
        uploader.should_receive(:upload).with(sample4_path, expected_post_params4).and_return(false)

        uploader = BatchUploader.new(config_path)
        uploader.run

        File.exist?(sample1_path).should be_true
        File.exist?(sample2_path).should be_false
        File.exist?(sample4_path).should be_true

        File.exist?(File.join(transfer_to_path, 'weather_station_01.dat')).should be_false
        File.exist?(File.join(transfer_to_path, 'weather_station_02.dat')).should be_true
        File.exist?(File.join(transfer_to_path_2, 'sample1.txt')).should be_false
      end
    end
  end
end

def create_test_file(path)
  File.open(path, 'w+') { |f| f.write('some random text') }
end

def write_yml(yml, path)
  File.open(path, 'w+') { |f| f.write(yml) }
end
