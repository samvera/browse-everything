BrowseEverything::Engine.routes.draw do
  get ":provider(/*path)", to: 'browse_everything#show', as: 'contents'
  match "connect", to: 'browse_everything#auth', as: 'connector_response', via:[:get,:post]
  root to: 'browse_everything#index'
end
