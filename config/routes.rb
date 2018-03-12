# frozen_string_literal: true

BrowseEverything::Engine.routes.draw do
  get 'connect', to: 'browse_everything#auth', as: 'connector_response'
  match 'resolve', to: 'browse_everything#resolve', as: 'resolver', via: %i[get post]
  match ':provider(/*path)', to: 'browse_everything#show', as: 'contents', via: %i[get post]
  root to: 'browse_everything#index'
end
