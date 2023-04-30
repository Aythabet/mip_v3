# Load the Rails environment
require File.expand_path('../config/environment', __dir__)

# Get all existing assignees
assignees = Assignee.all

# Loop through each assignee and update their vacation days
assignees.each do |assignee|
  if assignee.vacation_days_available.nil?
    assignee.calculate_vacation_days_available
    puts "Updated vacation days for assignee #{assignee.id}"
  end
end
