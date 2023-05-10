class TaskChangelog < ApplicationRecord
  belongs_to :task

  validates :changelog_id, presence: true, uniqueness: true
  after_create :generate_sentence_attribute

  private

  def generate_sentence_attribute
    self.update(sentence: "#{self.task.jira_id} - #{self.author} updated #{self.field} from '#{self.from_value}' to '#{self.to_value}' on #{self.timestamp}.")
  end
end
