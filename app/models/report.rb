class Report < ActiveRecord::Base
  belongs_to :reportable, polymorphic: true
  belongs_to :user

  validates :reportable_id, :reportable_type, :user_id, :reason, presence: true

  after_create :ghost_reportable
  def ghost_reportable
    reportable.ghost!
  end

  after_create :notify
  def notify
    ModeratorMailer.delay.report(id)
  end
end
