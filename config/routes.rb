BrowseEverything::Engine.routes.draw do
  get ":provider(/*path)", to: 'browse_everything#show'
  root to: 'browse_everything#index'
end
