# frozen_string_literal: true

BrowseEverything::Engine.routes.draw do
  get 'connect', to: 'browse_everything#auth', as: 'connector_response'
  match 'resolve', to: 'browse_everything#resolve', as: 'resolver', via: %i[get post]
  # The "format: false" argument ensures that directory paths containing period characters can be parsed
  # By default, ""/dir1/dir.somedirectory.2" will be parsed as "/dir1/dir" with the format requested as "somedirectory.2"
  # Please see http://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments
  match ':provider(/*path)', to: 'browse_everything#show', as: 'contents', via: %i[get post], format: false
  root to: 'browse_everything#index'
end
