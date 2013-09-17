BrowseEverything::Engine.routes.draw do
  get ":provider(/*path)", to: 'browse_everything#show', as: 'contents'
  root to: 'browse_everything#index'
end
