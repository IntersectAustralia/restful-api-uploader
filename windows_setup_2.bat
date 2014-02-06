copy sample_wrapper_config.yml ..\wrapper_config.yml /Y
copy sample_transfer_config.yml ..\transfer_config.yml /Y
echo ruby "%~dp0lib\run_wrapper.rb" "%~dp0..\wrapper_config.yml" "%~dp0..\transfer_config.yml">..\windows_api_load.bat
gem install httpclient --version 2.3.4.1
pause

