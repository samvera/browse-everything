BrowseEverything::Engine.routes.draw do
  get 'connect', to: 'browse_everything#auth', as: 'connector_response'
  match 'resolve', to: 'browse_everything#resolve', as: 'resolver', via: [:get, :post]
  match ':provider(/*path)', to: 'browse_everything#show', as: 'contents', via: [:get, :post]
  root to: 'browse_everything#index'
end
