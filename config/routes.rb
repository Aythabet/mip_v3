Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :assignees, only: [:index, :show]
  post 'assignees/retrieve_assignees'
  post 'assignees/destroy_all'

  resources :projects, only: [:index, :show]
  post 'projects/retrieve_projects'
  post 'projects/destroy_all'

  resources :tasks, only: [:index]
  post 'tasks/retrieve_tasks'
  post 'tasks/destroy_all'
end
