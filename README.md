# BrowseEverything

Code:
[![Gem Version](https://badge.fury.io/rb/browse-everything.png)](http://badge.fury.io/rb/browse-everything)
[![CircleCI](https://circleci.com/gh/samvera/browse-everything.svg?style=svg)](https://circleci.com/gh/samvera/browse-everything)
[![Coverage Status](https://coveralls.io/repos/samvera/browse-everything/badge.svg?branch=master&service=github)](https://coveralls.io/github/samvera/browse-everything?branch=master)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)

Jump in: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

# What is BrowseEverything?

This Gem allows your rails application to access user files from cloud storage.
Currently there are drivers implemented for [Dropbox](http://www.dropbox.com),
[Google Drive](http://drive.google.com),
[Box](http://www.box.com), [Amazon S3](https://aws.amazon.com/s3/),
and a server-side directory share.

The gem uses [OAuth](http://oauth.net/) to connect to a user's account and
generate a list of single use urls that your application can then use to
download the files.

**This gem does not depend on hydra-head**

## Product Owner & Maintenance

BrowseEverything is a Core Component of the Samvera community. The documentation for
what this means can be found
[here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

[mbklein](https://github.com/mbklein)

# Getting Started

## Supported Ruby Releases
Currently, the following releases of Ruby are supported:
- 2.7.0
- 2.6.5
- 2.5.7

## Supported Rails Releases
The supported Rail releases follow those specified by [the security policy of the Rails Community](https://rubyonrails.org/security/).  As is the case with the supported Ruby releases, it is recommended that one upgrades from any Rails release no longer receiving security updates.
- 6.0.2
- 5.2.4

_Support for Rails releases earlier than 5.2.z are dropped from 2.0.0 onwards in
order to maintain core compatibility with [Webpacker]()._

## Installing the Gem

Add this lines to your application's Gemfile:

    gem 'browse-everything'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install browse-everything

## Running the Rails Generator

After installing the gem, run the generator

    $ rails generate browse_everything:install

This generator will set up the _config/browse_everything_providers.yml_ file and
 add the browse-everything engine to your application's routes.

If you prefer not to use the generator, or need info on how to set up providers 
in the browse_everything_providers.yml, use the info on [Configuring browse-everything](https://github.com/samvera/browse-everything/wiki/Configuring-browse-everything).

## Architecture

From release 2.0.0 onwards, BrowseEverything relies upon a RESTful API to 
provide integration with Rails apps.  This API is defined using the [OpenAPI
Specification](https://swagger.io/specification/) by means of [Swagger](https://swagger.io/). Swagger automatically generates documentation for the API at [http://localhost:3000/browse/api-docs].

### JSON-API

Server responses are serialized using the [JSON-API](https://jsonapi.org/)
specification. As such, there are a number of options available when looking to
select client libraries for consuming and parsing this data at
https://jsonapi.org/implementations/#client-libraries

### Javascript and User Interfaces

As BrowseEverything is now a web API-driven application, it is not yet
bundled with any specific front-end for usage within a Rails application.
However, we would please recommend that you explore the forthcoming [React and
Redux user interface](https://github.com/samvera-labs/browse-everything-redux-react).

# Development

## Testing
This is a Rails Engine which is tested using the [engine_cart](https://github.com/cbeer/engine_cart) Gem and rspec.

Test suites may be executed with the following invocation:

```bash
bundle exec rake
```

### Testing with the User Interface
BrowseEverything *does* currently ship with a default test configuration for the 
[React user interface](https://github.com/samvera-labs/browse-everything-redux-react).
 The most straightforward approach to this is to invoke the following:

```bash
bundle exec rake engine_cart:generate
```

This will ensure that a new test app. is built which imports the React UI. This
can then be deployed using [foreman](https://rubygems.org/gems/foreman) with:

```bash
cd .internal_test_app
bundle exec foreman up
```

One need only access http://localhost:3000 in order to then use the UI with the
Rails API mounted from the Engine.

#### Working with a new UI branch

The UI version used for testing is the `master` branch of the GitHub repository
in the `.internal_test_app/package.json` file. This could be changed in order to
use your own fork instead. Simply change the following line in `package.json`:

```json
"browse-everything-react": "https://github.com/samvera-labs/browse-everything-redux-react",
```

...to something which follows the structure of:

```json
"browse-everything-react": "https://github.com/my-user/browse-everything-redux-react#my-branch",
```

After modifying the `package.json`, from within `.internal_test_app`, please invoke:

```bash
yarn install
```

If you wish to use a directory on your local environment, one must instead use
one of the following approaches:

##### [yarn link](https://classic.yarnpkg.com/en/docs/cli/link/#toc-yarn-link-in-package-you-want-to-link):
```bash
cd /Users/me/src/my-browse-everything-react
yarn link
cd /Users/me/src/browse-everything/.internal_test_app
yarn link "browse-everything-react"
```
_Note: Following this, please do *not* issue a `yarn install`, as this can break
the build._

In order to restore the `master` branch from from `samvera-labs`, one simple
invokes:
```bash
cd .internal_test_app
yarn unlink "browse-everything-react"
yarn install --force
```

##### Symbolic Links
However, there can be errors which arise when using `yarn link`. When these
occur, please instead invoke:
```bash
cd .internal_test_app/node_modules
rm -fr browse-everything-react
git clone https://github.com/me/my-browse-everything-react-fork.git browse-everything-react
cd ..
```

_Shouldn't one be able to use [yarn link](https://classic.yarnpkg.com/en/docs/cli/link/#toc-yarn-link-in-package-you-want-to-link) for this?_

Attempting to support this has led to bugs similar to what is detailed on
https://github.com/facebook/create-react-app/issues/3547#issuecomment-549372163.
 There is currently an [open issue for this](http://github.com/samvera/browse-everything/issues/329).

### Testing Problems
Should you attempt to execute the test suite and encounter the following error:
```bash
Your Ruby version is 2.x.x, but your Gemfile specified 2.y.z
```
...then you must clean the internal test app generated by `engine_cart` with the following:
```bash
bundle exec rake engine_cart:clean
```

## Adding Providers
In order to connect to a provider like [Dropbox](http://www.dropbox.com),
[Google Drive](http://drive.google.com), or
[Box](http://www.box.com), you must provide API keys in _config/browse_everything_providers.yml_.  For info on how to edit this file, see [Configuring browse-everything](https://github.com/samvera/browse-everything/wiki/Configuring-browse-everything)

### Retrieving Files
`BrowseEverything::Upload` objects are created upon users selecting a set of
files for download, and the successful submission of a form (this is, of course,
overlaying a `POST` request to the web API).  Upon successfully creating an
`Upload`, an ID is provided in the JSON-API server response:

```json
example here
```

Within the Rails app, the newly-created `Upload` is retrieved using the
following:

```ruby
uploads = BrowseEverything::Upload.find_by(uuid: upload_uuid)
upload = uploads.first
upload.files.each do |file|
  bytes = file.bytestream.download
  # Do something with the bytes here
end
```

The objects retrieved using `#files` are `BrowseEverything::UploadFile` objects,
which implement [ActiveStorage](https://guides.rubyonrails.org/active_storage_overview.html) for providing access to the file downloaded from the provider. `ActiveStorage`
, by default, writes these downloads to the file system.  This may be configured
 by referencing the [documentation](http://guides.rubyonrails.org/active_storage_overview.html#setup).

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)
