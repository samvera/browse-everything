[![Build Status](https://travis-ci.org/projecthydra/browse-everything.png?branch=master)](https://travis-ci.org/projecthydra/browse-everything)

# BrowseEverything

This Gem allows your rails application to access user files from cloud storage.  
Currently there are drivers implemented for [DropBox](http://www.dropbox.com), 
[Skydrive](https://skydrive.live.com/), [Google Drive](http://drive.google.com), 
[Box](http://www.box.com), and a server-side directory share.

The gem uses [OAuth](http://oauth.net/) to connect to a user's account and 
generate a list of single use urls that your application can then use to 
download the files.

## Installation

Add this line to your application's Gemfile:

    gem 'browse-everything'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install browse-everything

## Usage

### Configuration

To use the gem you will need to configure the providers by providing applcation keys that are required by each provider

An example config/browse_everything_providers.yml:

```yaml
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

You must register your application with each cloud provider separately:

* Skydrive: [https://account.live.com/developers/applications/create](https://account.live.com/developers/applications/create)
* Dropbox: [https://www.dropbox.com/developers/apps/create](https://www.dropbox.com/developers/apps/create)
* Box: [https://app.box.com/developers/services/edit/](https://app.box.com/developers/services/edit/)
* GoogleDrive: [https://code.google.com/apis/console](https://code.google.com/apis/console)

### CSS and JavaScript Modifications

Add `@import "browse_everything` to your application.css.scss

Add `//= require browse_everything` to your application.js

### Routes

Mount the engine in your routes.rb

```
  mount BrowseEverything::Engine => '/browse'
```

### Views

browse-everything can be triggered in one of two ways:

#### Via data attributes

```html
<button type="button" data-toggle="browse-everything" data-route="<%=browse_everything_engine.root_path%>" 
  data-target="#myForm" class="btn btn-large btn-success" id="browse">Browse!</button>
```

#### Via JavaScript

```javascript
$('#browse').browseEverything(options)
```

#### Options

Options can be passed via data attributes or JavaScript. For data attributes, append the option name to `data-`, 
as in `data-target="#myForm"`.

| Name            | type            | default         | description                                                    |
|-----------------|-----------------|-----------------|----------------------------------------------------------------|
| route           | path (required) | ''              | The base route of the browse-everything engine.                |
| target          | xpath or jQuery | null            | A form object to add the results to as hidden fields.          |

If a `target` is provided, browse-everything will automatically convert the JSON response to a series of hidden form fields
that can be posted back to Rails to re-create the array on the server side. 

#### Methods

##### .browseEverything(options)

Attaches the browsing behavior to the click event of the receiver.

```javascript
$('#browse').browseEverything({
  route: "/browse",
  target: "#myForm"
}).done(function(data) {
  // User has submitted files; data contains an array of URLs and their options
}).cancel(function() {
  // User cancelled the browse operation
}).fail(function(status, error, text) {
  // URL retrieval experienced a techical failure
});
```

##### .browseEverything()

Returns the existing callback object for the receiver, allowing for a mix of data attribute and JavaScript modes.

```html
<button type="button" data-toggle="browse-everything" data-route="/browse" 
  data-target="#myForm" class="btn btn-large btn-success" id="browse">Browse!</button>

<script>
  $(document).ready(function() {
    $('#browse').browseEverything().done(function(data) {
      // Set the "done" callback for the already-defined #browse button
    })
  });
</script>
```

#### Data Structure

browse-everything returns a JSON data structure consisting of an array of URL specifications. Each URL specification
is a plain object with the following properties:

| Property           | Description                                                                          |
|--------------------|--------------------------------------------------------------------------------------|
| url                | The URL of the selected remote file.                                                 |
| auth_header        | Any headers that need to be added to the request in order to access the remote file. |
| expires            | The expiration date/time of the specified URL.                                       |

### Examples

See `spec/support/app/views/file_handler/index.html` for an example use case. You can also run `rake app:generate` to
create a fully-functioning demo app in `spec/internal` (though you will have to create 
`spec/internal/config/browse_everything.providers.yml` file with your own configuration info.)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
