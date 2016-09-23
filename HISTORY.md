### 0.10.5 (2016-09-23)
  Fix naming conflict that broke the `context` option in 0.10.4.

### 0.10.4 (2016-08-05)
  Don't wait for auto-toggle if the explicit browseEverything() call is seen first.

### 0.10.3 (2016-07-12)
  Support turbolinks 5 and previous versions
  Optionally adding state to url so box and dropbox will work

### 0.10.2 (2016-05-31)
  Pin google-api-client to 0.8.x
  
### 0.10.1 (2016-05-31)
  Fix dropbox integration
  Change badge URLs to reflect promotion out of labs
  Fix String.prototype.replace() global flag deprecation warning
  
### 0.10.0 (2016-04-04)
  Add browse_everything:install generator, delegating to the assets and config generators, to install the dependencies into the application
  Extract browse_everything css into a separate file that can be included without also including bootstrap and font-awesome
  Drop Ruby 1.9 support
  Use bootstrap-sprockets instead
  Disable bundler caching between test runs
  Update to engine_cart v0.8.0
  Add Coveralls support
  Allow ERB in YAML config

### 0.9.1 (2015-10-22)
- Properly scope "Select All" checkbox triggers (Bug: @awead / Fix: @awead)

### 0.9.0 (2015-10-21)
- Add Select All and Recursive Select capabilities
- Speed up Box API calls
- Add Jasmine tests

### 0.8.4 (2015-10-01)
- Bug fixes for Box provider
- Text fixture fixes for Dropbox provider

### 0.8.3 (2015-09-30)
- Improve compatibility with Rails 4.2.x
- Minor bug fixes

### 0.8.2 (2015-04-15)
- Add support for latest 4.1 and 4.2 Rails versions
- Add support for %20 encoded URLs
- Use Dropbox name consistently

### 0.8.1 (2015-03-03)
- Use numeric size from Dropbox instead of string value

### 0.8.0 (2015-02-27)
- Add `max_upload_file_size` option to configuration
- Disable selection of files that are larger than `max_upload_file_size`

### 0.7.1 (2014-12-23)
- Rails 4.2 support

### 0.7.0 (2014-12-10)
- Add BrowseEverything::Retriever
- Accessibility improvements
- Bug fixes

### 0.6.3 (2014-08-06)
- Treat FontAwesome version issues independently of Bootstrap version issues

### 0.6.2 (2014-08-06)
- Fix Bootstrap/FontAwesome cross-version styling issues

### 0.6.1 (2014-07-31)
- Fix auto-refresh after authorizing cloud provider

### 0.6.0 (2014-07-31)
- Move provider list from left column to dropdown in header

### 0.5.2 (2014-07-30)
- Allow MIME type filtering to work on Rack < 1.5.0

### 0.5.1 (2014-07-30)
- Fix for busted responsive layouts when using Bootstrap 2.x

### 0.5.0 (2014-07-29)
- New, prettier tree-oriented UI
- Added app-specific `context` parameter
- Added `accept` parameter to allow filtering of results based on MIME type
- Added `show()` callback

### 0.4.5 (2014-06-20)
- Fix for filenames with special entities in them

### 0.4.4 (2014-06-19)
- Add browse-everything assets to asset precompile

### 0.4.3 (2014-05-07)
- More robust Turbolinks/non-Turbolinks initialization support

### 0.4.2 (2014-04-25)
- Fixed TurboLinks-related initialization bugs
- Added TurboLinks testing options to internal test app

### 0.4.1 (2014-04-03)
- Bug fixes
- TurboLinks compatibility

### 0.4.0 (2014-04-01)
- Added configuration generator
- Improved documentation

### 0.3.0 (2014-03-24)
- Additional response parameters
- Refresh token fixes for Box, SkyDrive, and Google Drive

### 0.2.0 (2013-12-03)
- Bootstrap 2/3 cross-compatibility

### 0.1.0 (2013-09-24)
- Initial release
