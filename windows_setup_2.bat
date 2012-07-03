copy sample_config.yml ..\config.yml /Y

echo ruby "%~dp0lib\run_batch.rb" "%~dp0..\config.yml">..\windows_api_load.bat

gem install bundler --version 1.1.4
bundle install --without=development
