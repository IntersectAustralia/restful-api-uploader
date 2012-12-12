copy sample_config.yml ..\config.yml /Y
echo ruby "%~dp0lib\run_wrapper.rb" "%~dp0..\wrapper_config.yml" "%~dp0..\transfer_config.yml>..\windows_api_load.bat
gem install rest-client --version 1.6.7
pause

