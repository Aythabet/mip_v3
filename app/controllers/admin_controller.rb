class AdminController < ApplicationController
  before_action :check_admin

  def all_vacations
    @active_vacations = Vacation.where(
      "start_date <= ? AND ? <= (start_date + interval '1 day' * ((duration - 0.5) * 2))",
      Date.today,
      Date.today
    )
  end
end
