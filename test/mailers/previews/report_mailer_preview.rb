# Preview all emails at http://localhost:3000/rails/mailers/report_mailer
class ReportMailerPreview < ActionMailer::Preview
  def send_data_to_user
    assignee = Assignee.where(email: "safa.bouarrouj@inspiregroup.io").first
    ReportMailer.send_data_to_user(assignee)
  end
end
