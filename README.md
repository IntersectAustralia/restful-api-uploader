restful-api-uploader
====================

A set of ruby scripts and configuration for uploading files to a RESTful API endpoint using multipart HTTP POST.

This is intended to be used for scenarios where we want to run scheduled uploads of automatically generated data files.

It was built for DC21 but could be used for any application by supplying the required configuration file. Configuration
is provided via a YAML file, which specifies the server location and then a set of files to be uploaded. Refer to
sample_config.yml in the root directory for an example. Currently the response is just logged to a file, and nothing more
is done. This could be extended in the future to do more elaborate handling of the response.