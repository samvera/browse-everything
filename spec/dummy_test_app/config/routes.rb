Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount BrowseEverything::Engine => '/browse'

  # Custom actions we use for feature testing
  root :to => "file_handler#index"
  get '/main', :to => "file_handler#main"
  post '/file', :to => "file_handler#update"
end
