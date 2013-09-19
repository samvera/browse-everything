BrowseEverything::Engine.routes.draw do
  get "connect", to: 'browse_everything#auth', as: 'connector_response'
  post "resolve", to: 'browse_everything#resolve', as: 'resolver'
  get ":provider(/*path)", to: 'browse_everything#show', as: 'contents'
  root to: 'browse_everything#index'
end
