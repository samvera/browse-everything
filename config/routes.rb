# frozen_string_literal: true

BrowseEverything::Engine.routes.draw do
  # Supporting other RESTful operations should be done for sessions
  resources :sessions, controller: 'browse_everything/sessions', only: [:create, :show, :destroy, :index] do
    # I'm not certain what :index would imply here - but it might be useful to
    # request all possible containers within the scope of a
    # session
    resources :bytestreams, controller: 'browse_everything/bytestreams', only: [:show]
    resources :containers, controller: 'browse_everything/containers', only: [:show, :index]
  end
  # This actually is not used by the current client - should these be exposed?
  resources :authorizations, controller: 'browse_everything/authorizations', only: [:show, :destroy]

  resources :providers, controller: 'browse_everything/providers', only: [:show, :index]
  # We cannot support updating uploads, as then we would need to cancel the job for the files
  resources :uploads, controller: 'browse_everything/uploads', only: [:create, :show, :destroy, :index]

  # This is the route which will be needed for the OAuth callback URL
  # Rails defaults to accepting POST requests, so this might not work
  #   Within which the GET query parameters will instead be parsed
  #   This would probably violate the principles of RESTful architecture
  # This is a custom action for the OAuth callback
  get 'providers/:provider_id/authorize', to: 'browse_everything/providers#authorize', as: 'provider_authorize'
end
