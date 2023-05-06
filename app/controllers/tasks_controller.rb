class TasksController < ApplicationController
  def index
    breadcrumbs.add "Tasks", tasks_path

    @tasks = Task.order(updated_at: :desc)
    @tasks = @tasks.where("jira_id LIKE ?", "%#{params[:query].upcase}%") if params[:query].present?
    @tasks = @tasks.page params[:page]

    if turbo_frame_request?
      render partial: "tasks", locals: { tasks: @tasks }
    else
      render :index
    end

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
