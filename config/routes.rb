BrowseEverything::Engine.routes.draw do
  match "connect", to: 'browse_everything#auth', as: 'connector_response', via:[:get,:post]
  get ":provider(/*path)", to: 'browse_everything#show', as: 'contents'
  root to: 'browse_everything#index'
end
