[![Build Status](https://travis-ci.org/projecthydra/browse-everything.png?branch=master)](https://travis-ci.org/projecthydra/browse-everything)

# BrowseEverything

This Gem allows your rails application to access user files from cloud storage.  
Currently there are drivers implemented for DropBox, Skydrive, GoogleDrive, box, and a server directory share.

The gem uses OAuth to connect into the user files and generate a list of single use urls that your application can then use to download the files.

## Installation

Add this line to your application's Gemfile:

    gem 'browse_everything'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install browse_everything

## Usage

### Configuration

To use the gem you will need to configure the providers by providing applcation keys that are required by each provider

An example config/browse_everything_providers.yml:
```
---
file_system:
  :home: /<location for server file drop>
sky_drive:
  :client_id: <your client id>
  :client_secret: <your client secret>
box:
  :client_id: <your client id>
  :client_secret: <your client secret>
drop_box:
  :app_key: <your client id>
  :app_secret: <your app secret>
google_drive:
  :client_id: <your client id>
  :client_secret: <your client secret>
```
To register your application for ids you must go to each cloud provider.
* Skydrive: https://account.live.com/developers/applications/create
* Dropbox: https://www.dropbox.com/developers/apps/create
* Box: https://app.box.com/developers/services/edit/
* GoogleDrive: https://code.google.com/apis/console

### CSS and JavaScript Modifications

Add `@import "browse_everything` to your application.css.scss

Add `//= require browse_everything` to your application.js

### Routes

Mount the engine in your routes.rb

```
  mount BrowseEverything::Engine => '/browse'
  root :to => "file_handler#index"
  post '/file', :to => "file_handler#update", :as => "browse_everything_file_handler"

```
### Views

Add `<button class="btn btn-large btn-success" id="browse" data-toggle="browse-everything" data-route="<%=browse_everything_engine.root_path%>">Browse</button>`

See spec/support/app/views/file_handler/index.html for an example use case.

### Controller

See spec/support/app/controlelrs/file_handler_controller.rb

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
