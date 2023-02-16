Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  get 'admin_actions/assignees', to: 'admin_actions#assignees'
  post 'admin_actions/retrieve_assignees'

  resources :projects, only: [:index, :show]
  post 'projects/retrieve_projects'
end
