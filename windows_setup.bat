rubyinstaller\rubyinstaller.exe /verysilent /tasks="assocfiles,modpath"
copy sample_config.yml ..\config.yml /Y
copy windows_api_load.bat ..\windows_api_load.bat /Y
gem install bundler --version 1.1.4
bundle install --without=development
