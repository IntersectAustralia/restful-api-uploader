restful-api-uploader
====================
A set of ruby scripts and configuration for uploading files to a RESTful API endpoint using multipart HTTP POST.

This is intended to be used for scenarios where we want to run scheduled uploads of automatically generated data files.

This was built for [DC21](https://github.com/IntersectAustralia/dc21) but could be used for any application by supplying the required configuration file. Configuration
is provided via two YAML files, which specify the server location and then a set of files to be uploaded. Refer to
sample_wrapper_config.yml and sample_transfer_config.yml in the root directory for examples. Alternatively, you can refer to user instructions at https://github.com/IntersectAustralia/dc21/wiki/Setting-Up-Automated-Load-From-PC .

This was built by [Intersect Australia](http://www.intersect.org.au/) for the Hawkesbury Institute for the Environment at the University of Western Sydney as part of [ANDS-Funded Data Capture Project (DC21)](http://www.ands.org.au).

This code is licensed under the GNU GPL v3 license - see LICENSE.txt
