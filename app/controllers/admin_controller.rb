class AdminController < ApplicationController
  before_action :check_admin

  def all_vacations
    @active_vacations = Vacation.where("start_date <= ? AND ? <= (start_date + interval '1 day' * (duration - 1))", Date.today, Date.today)
  end
end
