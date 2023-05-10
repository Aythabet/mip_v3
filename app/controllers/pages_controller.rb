class PagesController < ApplicationController
  before_action :authenticate_user!

  def home
    basic_stats_projects_assignees_tasks
    active_tickets_partial
    @last_jira_update = JobsLog.where(title: ["TasksJob", "ImportTasksScheduler"]).order(created_at: :desc).first
  end

  def tests
    breadcrumbs.add "Tests", tests_path

    url = "https://agenceinspire.atlassian.net/rest/api/3/issue/RB-10/comment"
    uri = URI.parse(url)

    body_data = {
      "body": {
        "content": [
          {
            "content": [
              {
                "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque eget venenatis elit. Duis eu justo eget augue iaculis fermentum. Sed semper quam laoreet nisi egestas at posuere augue semper.",
                "type": "text",
              },
            ],
            "type": "paragraph",
          },
        ],
        "type": "doc",
        "version": 1,
      },
    }.to_json

    headers = {
      "Authorization" => "Basic #{ENV["JIRA_API_TOKEN"]}",
      "Content-Type" => "application/json",
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = body_data

    @response = http.request(request)

    puts "Response: #{@response.code} #{@response.message}"
    puts @response.body
  end

  private

  def basic_stats_projects_assignees_tasks
    @total_number_of_projects = Project.count
    @total_number_of_tasks = Task.count
    @total_number_of_assignees = Assignee.count
  end

  def active_tickets_partial
    projects = Project
      .joins(:tasks)
      .where(tasks: { status: ["In Progress", "En cours", "en cours"] })
      .distinct
      .includes(:tasks)

    active_and_on_hold_tasks_count(projects)

    unique_tasks_count = Task.group(:status).count
    @unique_tasks_count = unique_tasks_count.sort_by { |status, count| count }.reverse
    @projects_with_active_tickets = projects.sort_by { |project| -1 * project.tasks.where(status: ["In Progress", "En cours", "en cours"]).count }
  end

  def active_and_on_hold_tasks_count(projects)
    @in_progress_tasks_count = 0
    @on_hold_tasks_count = 0
    projects.each do |project|
      @in_progress_tasks_count += project.tasks.where(status: ["In Progress", "En cours", "en cours"]).count
      @on_hold_tasks_count += project.tasks.where(status: ["En attente", "En Pause", "On Hold"]).count
    end
  end
end
