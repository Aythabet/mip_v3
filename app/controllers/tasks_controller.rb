class TasksController < ApplicationController
  def index
    @tasks = Task.all.order(updated_at: :desc).page params[:page]
    @tasks_count = Task.count
  end

  def retrieve_tasks
    TasksJob.perform_async

    flash.notice = 'The import started, come back in few minutes!'
    redirect_to tasks_path
  end

  def destroy_all
    DestroyTasksJob.perform_async

    flash.notice = 'All the tasks will be deleted.'
    redirect_to tasks_path
  end
end
