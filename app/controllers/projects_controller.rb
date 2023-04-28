class ProjectsController < ApplicationController
  def index
    # Get projects with active tasks and order by number of active tasks
    active_projects = Project
    .joins(:tasks)
    .where('tasks.status = ?', 'In Progress')
    .group('projects.id')
    .order(Arel.sql('COUNT(DISTINCT tasks.id) DESC'))

    # Get remaining projects and concatenate the two lists
    inactive_projects = Project.where.not(id: active_projects)
    @projects = Kaminari.paginate_array(active_projects.to_a + inactive_projects.to_a)
    .page(params[:page])

    # Get the total count of projects
    @projects_count = Project.count
  end

  def retrieve_projects
    get_projects_data_with_pagination(0)
    get_projects_data_with_pagination(50)
    redirect_to projects_path
  end

  def show
    @project = Project.find(params[:id])
    @project_tasks = Task.where(project: @project).order(last_jira_update: :desc)
    @project_tasks_paginated = Task.where(project: @project).order(last_jira_update: :desc).page params[:page]

    projects_unique_assignees_list
    projects_unique_statuses_list
    @tasks_by_time_status = tasks_by_time_status

    @total_time_estimation = 0
    @total_time_spent = 0

    @project_tasks.each do |task|
      @total_time_estimation += task.time_forecast || 0
      @total_time_spent += task.time_spent || 0
      @time_difference = @total_time_estimation - @total_time_spent
    end
  end

  def project_details
    @project = Project.find(params[:id])

    @projects_assignees = Assignee.joins(tasks: :project)
    .select("assignees.*, SUM(tasks.time_spent) AS total_time_spent")
    .where(tasks: { project_id: @project.id })
    .group("assignees.id")

    @project_total_internal_cost = Task.joins(:assignee)
    .where(project: @project)
    .sum("tasks.time_spent * (assignees.hourly_rate / 3600)")

  end


  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])

    if @project.update(project_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'selling_price',
            partial: 'projects/edit',
            locals: { project: @project }
          )
        end
        format.html { redirect_to project_details_path(@project) }
      end

    else
      render :edit
    end
  end

  def destroy_all
    Project.destroy_all
    redirect_to projects_path
  end

  private

  def project_params
    params.require(:project).permit(:name, :jira_id, :archived_status, :lead, :total_internal_cost, :total_selling_price)
  end

  def get_projects_data_with_pagination(startat)
    url = "https://agenceinspire.atlassian.net/rest/api/3/project/search?startAt=#{startat}&maxResults=50&expand=lead"
    response = call_jira_api(url)
    return unless response.code == '200'

    json_projects = JSON.parse(response.body)
    collect_projects_information(json_projects)
  end

  def collect_projects_information(json_projects)
    i = 0
    json = json_projects['values']
    while i < json.length
      project_name = json[i]['name']
      project_jira_id = json[i]['key']
      project_lead = json[i]['lead']['displayName']
      find_or_create_project(project_name, project_jira_id, project_lead)
      i += 1
    end
  end

  def find_or_create_project(project_name, project_jira_id, project_lead)
    Project.find_or_create_by(name: project_name) do |project|
      project.jira_id = project_jira_id
      project.lead = project_lead
    end
  end

  def projects_unique_assignees_list
    # Load the project by ID
    @project = Project.find(params[:id])

    # Load all the unique assignees for the project's tasks
    assignee_names = @project.tasks.select(:assignee_id).distinct.joins(:assignee).pluck('assignees.name')

    # Extract the full names from the array of names
    @projects_unique_assignees = assignee_names.map { |name| name.split(' ').map(&:capitalize).join(' ') }

    @assignee_task_counts = {}
    @project.tasks.group(:assignee_id).count.each do |assignee_id, task_count|
      @assignee_task_counts[Assignee.find(assignee_id).name] = task_count
    end

    @assignee_task_percentages = {}
    total_tasks = @project.tasks.count
    @assignee_task_counts.each do |assignee, task_count|
      @assignee_task_percentages[assignee] = (task_count.to_f / total_tasks * 100).round(2)
    end

    @assignee_time_spent = {}
    @project.tasks.joins(:assignee).group("assignees.name").sum(:time_spent).each do |assignee_name, time_spent|
      @assignee_time_spent[assignee_name] = time_spent
    end

    # Sort the unique assignees by the number of tasks in descending order
    @projects_unique_assignees.sort_by! { |assignee| -@assignee_task_counts[assignee] }
  end

  def projects_unique_statuses_list
    # Load the project by ID
    @project = Project.find(params[:id])

    # Load all the unique statuses for the project's tasks
    status_names = @project.tasks.select(:status).distinct.pluck(:status)

    # Extract the full names from the array of names
    @projects_unique_statuses = status_names.map(&:capitalize)

    # Get the count and percentage of tasks for each status
    @status_task_counts = {}
    total_tasks = @project.tasks.count
    @project.tasks.group(:status).count.each do |status, task_count|
      @status_task_counts[status.capitalize] = task_count
    end

    @status_task_percentages = {}
    @status_task_counts.each do |status, task_count|
      @status_task_percentages[status] = (task_count.to_f / total_tasks * 100).round(2)
    end

    # Sort the unique statuses by the number of tasks in descending order
    @projects_unique_statuses.sort_by! { |status| -@status_task_counts[status] }
  end

  def tasks_by_time_status
    project = Project.find(params[:id])
    total_tasks = project.tasks.count
    in_time_tasks = project.tasks.where("time_spent = time_forecast").count
    early_tasks = project.tasks.where("time_spent < time_forecast").count
    delayed_tasks = project.tasks.where("time_spent > time_forecast").count
    no_data_tasks = project.tasks.where("time_forecast IS NULL OR time_spent IS NULL").count

    in_time_percentage = (in_time_tasks.to_f / total_tasks.to_f * 100).round(2)
    early_percentage = (early_tasks.to_f / total_tasks.to_f * 100).round(2)
    delayed_percentage = (delayed_tasks.to_f / total_tasks.to_f * 100).round(2)
    no_data_percentage = (no_data_tasks.to_f / total_tasks.to_f * 100).round(2)

    { in_time: { count: in_time_tasks, percentage: in_time_percentage },
      early: { count: early_tasks, percentage: early_percentage },
      delayed: { count: delayed_tasks, percentage: delayed_percentage },
      no_data: {count: no_data_tasks, percentage: no_data_percentage }}
  end

end
