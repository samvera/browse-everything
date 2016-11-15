[![Gem Version](https://badge.fury.io/rb/browse-everything.png)](http://badge.fury.io/rb/browse-everything)
[![Build Status](https://travis-ci.org/projecthydra/browse-everything.svg?branch=master)](https://travis-ci.org/projecthydra/browse-everything)
[![Coverage Status](https://coveralls.io/repos/projecthydra/browse-everything/badge.svg?branch=master&service=github)](https://coveralls.io/github/projecthydra/browse-everything?branch=master)

# BrowseEverything

This Gem allows your rails application to access user files from cloud storage.
Currently there are drivers implemented for [Dropbox](http://www.dropbox.com),
[Skydrive](https://skydrive.live.com/), [Google Drive](http://drive.google.com),
[Box](http://www.box.com),[Kaltura](http://www.kaltura.com) and a server-side directory share.

The gem uses [OAuth](http://oauth.net/) to connect to a user's account and
generate a list of single use urls that your application can then use to
download the files.

**This gem does not depend on hydra-head**

## Installation

Add this line to your application's Gemfile:

    gem 'browse-everything'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install browse-everything

### Configuring the gem

After installing the gem, run the generator

    $ rails g browse_everything:install

This generator will set up the _config/browse_everything_providers.yml_ file and add the browse-everything engine to your application's routes.

If you prefer not to use the generator, or need info on how to set up providers in the browse_everything_providers.yml, use the info on [Configuring browse-everything](https://github.com/projecthydra/browse-everything/wiki/Configuring-browse-everything).

### Include the CSS and JavaScript

Add `@import "browse_everything";` to your application.css.scss

Add `//= require browse_everything` to your application.js

## Usage

### Adding Providers
In order to connect to a provider like [Dropbox](http://www.dropbox.com),
[Skydrive](https://skydrive.live.com/), [Google Drive](http://drive.google.com), or
[Box](http://www.box.com), [Kaltura](http://www.kaltura.com), you must provide API keys in _config/browse_everything_providers.yml_.  For info on how to edit this file, see [Configuring browse-everything](https://github.com/projecthydra/browse-everything/wiki/Configuring-browse-everything)

### Views

browse-everything can be triggered in two ways -- either via data attributes in an HTML tag or via JavaScript.  Either way, it accepts the same options:

#### Options

| Name            | Type            | Default         | Description |
|-----------------|-----------------|-----------------|----------------------------------------------------------------|
| route           | path (required) | ''              | The base route of the browse-everything engine.                |
| target          | xpath or jQuery | null            | A form object to add the results to as hidden fields.          |
| context         | text            | null            | App-specific context information (passed with each request)    |
| accept          | MIME mask       | */*             | A list of acceptable MIME types to browse (e.g., 'video/*')    |

If a `target` is provided, browse-everything will automatically convert the JSON response to a series of hidden form fields
that can be posted back to Rails to re-create the array on the server side.

#### Via data attributes

To trigger browse-everything using data attributes, set the _data-toggle_ attribute to "browse-everything" on the HTML tag.  This tells the javascript where to attach the browse-everything behaviors. Pass in the options using the _data-route_ and _data-target_ attributes, as in `data-target="#myForm"`.

For example:

```html
<button type="button" data-toggle="browse-everything" data-route="<%=browse_everything_engine.root_path%>"
  data-target="#myForm" class="btn btn-large btn-success" id="browse">Browse!</button>
```

#### Via JavaScript

To trigger browse-everything via javascript, use the .browseEverything() method to attach the behaviors to DOM elements.

```javascript
$('#browse').browseEverything(options)
```

The options argument should be a JSON object with the route and (optionally) target values set.  For example:
```javascript
$('#browse').browseEverything({
  route: "/browse",
  target: "#myForm"
})
```

See [JavaScript Methods](https://github.com/projecthydra/browse-everything/wiki/JavaScript-Methods) for more info on using javascript to trigger browse-everything.

### The Results (Data Structure)

browse-everything returns a JSON data structure consisting of an array of URL specifications. Each URL specification
is a plain object with the following properties:

| Property           | Description |
|--------------------|--------------------------------------------------------------------------------------|
| url                | The URL of the selected remote file. |
| auth_header        | Any headers that need to be added to the request in order to access the remote file. |
| expires            | The expiration date/time of the specified URL. |
| file_name          | The base name (filename.ext) of the selected file.                                   |

For example, after picking two files from dropbox,

If you initialized browse-everything via JavaScript, the results data passed to the `.done()` callback will look like this:
```json
[
  {
    "url": "https://dl.dropbox.com/fake/filepicker-demo.txt.txt",
    "expires": "2014-03-31T20:37:36.214Z",
    "file_name": "filepicker-demo.txt.txt"
  }, {
    "url": "https://dl.dropbox.com/fake/Getting%20Started.pdf",
    "expires": "2014-03-31T20:37:36.731Z",
    "file_name": "Getting Started.pdf"
  }
]
```
See [JavaScript Methods](https://github.com/projecthydra/browse-everything/wiki/JavaScript-Methods) for more info on using javascript to trigger browse-everything.

If you initialized browse-everything via data-attributes and set the _target_ option (via the _data-target_ attribute or via the _target_ option on the javascript method), the results data be written as hidden fields in the `<form>` you've specified as the target.  When the user submits that form, the results will look like this:
```ruby
"selected_files" => {
  "0"=>{
    "url"=>"https://dl.dropbox.com/fake/filepicker-demo.txt.txt",
    "expires"=>"2014-03-31T20:37:36.214Z",
    "file_name"=>"filepicker-demo.txt.txt"
  },
  "1"=>{
    "url"=>"https://dl.dropbox.com/fake/Getting%20Started.pdf",
    "expires"=>"2014-03-31T20:37:36.731Z",
    "file_name"=>"Getting Started.pdf"
  }
}
```

### Retrieving Files

The `BrowseEverything::Retriever` class has two methods, `#retrieve` and `#download`, that
can be used to retrieve selected content. `#retrieve` streams the file by yielding it, chunk
by chunk, to a block, while `#download` saves it to a local file.

Given the above response data:

```ruby
retriever = BrowseEverything::Retriever.new
download_spec = params['selected_files']['1']

# Retrieve the file, yielding each chunk to a block
retriever.retrieve(download_spec) do |chunk, retrieved, total|
  # do something with the `chunk` of data received, and/or
  # display some progress using `retrieved` and `total` bytes.
end

# Download the file. If `target_file` isn't specified, the
# retriever will create a tempfile and return the name.
retriever.download(download_spec, target_file) do |filename, retrieved, total|
  # The block is still useful for showing progress, but the
  # first argument is the filename instead of a chunk of data.
end
```

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

## Help

For help with Questioning Authority, contact <hydra-tech@googlegroups.com>.
