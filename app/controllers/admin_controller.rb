class AdminController < ApplicationController
  before_action :check_admin

  def all_vacations
    breadcrumbs.add "Vacations", all_vacations_path

    @active_vacations = Vacation.where(
      "start_date <= ? AND ? <= (start_date + interval '1 day' * ((duration - 0.5) * 2))",
      Date.today,
      Date.today
    )
    @upcoming_vacations = Vacation.where(
      "start_date >= ? AND ? <= (start_date + interval '1 day' * ((duration - 0.5) * 2))",
      Date.today,
      Date.today
    ).where.not(
      "start_date <= ? AND ? <= (start_date + interval '1 day' * ((duration - 0.5) * 2))",
      Date.today,
      Date.today
    )
  end
end
