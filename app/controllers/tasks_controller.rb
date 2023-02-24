class TasksController < ApplicationController
  def index
    @tasks = Task.all.order(updated_at: :desc).page params[:page]
    @tasks_count = Task.count
  end

  def retrieve_tasks
    TasksJob.perform_at(5.minutes.from_now)
  end

  def destroy_all
    Task.destroy_all
    redirect_to tasks_path
  end
end
