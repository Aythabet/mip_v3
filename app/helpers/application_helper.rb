module ApplicationHelper

  def my_helper_format_duration(seconds)
    ApplicationController.new.format_duration(seconds)
  end
end
