class ReportMailer < ApplicationMailer
  def send_data_to_user(assignee)
    @assignee = assignee
    @data =  Task.where(assignee_id: assignee.id, status: 'In Progress')

    mail(to: @assignee.email, subject: 'Data from My App')
  end
end
