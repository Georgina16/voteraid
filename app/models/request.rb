class Request < ApplicationRecord
  include AASM #request as a state machine
  belongs_to :responder, inverse_of: :requests, optional: true
  has_many :messages, inverse_of: :request

  enum issue: [:unknown, :id_problem, :not_on_registration_list, :eligibility_challenged, :check_in, :voting_machine, :line_too_long, :provisional_problem, :other]
  enum status: {
         new_request: 1,
         awaiting_address: 2,
         awaiting_issue: 3,
         check_need_responder: 4,
         awaiting_desc: 5,
         pending_responder: 6,
         responder_assigned: 7,
         awaiting_feedback: 8,
         resolved: 9,
         unresolved: 10
       }
  aasm column: :status, enum: true do
    state :new_request, initial: true
    state :awaiting_address, :awaiting_issue, :check_need_responder, :awaiting_desc, :pending_responder, :responder_assigned, :pending_feedback, :resolved, :unresolved

    event :process do
      transitions from: :new_request, to: :awaiting_address
      transitions from: :awaiting_address, to: :awaiting_issue, after: Proc.new {|_, message| save_address(message) }
      transitions from: :awaiting_issue, to: :check_need_responder, if: Proc.new {|_, message| save_issue(message) }
      transitions from: :check_need_responder, to: :awaiting_desc, if: Proc.new {|_, message| affirmative?(message) }
      transitions from: :check_need_responder, to: :resolved, if: Proc.new {|_, message| negative?(message) }
      transitions from: :awaiting_desc, to: :pending_responder, if: Proc.new{|_, message| has_nearby_responders? }
      transitions from: :awaiting_desc, to: :unresolved
      transitions from: :pending_responder, to: :responder_assigned
      transitions from: :responder_assigned, to: :awaiting_feedback
    end


  end

  def save_address(msg)
    self.address = msg.body
  end

  def save_issue(msg)
    digit = valid_issue?(msg)
    if digit
      self.issue = digit
    else
      return false
    end
  end

  def set_responder(responder_id)
    self.responder_id = responder_id
    self.save
  end

  def has_nearby_responders?
    return Responder.near(self.address,50).count(:all) > 0
  end

  private

  def valid_issue?(msg)
    digit = /\d/.match(msg.body)[0].to_i
    if digit > 0 and digit < Request.issues.count
      return digit
    else
      return false
    end
  end

  def affirmative?(msg)
    return /y(es)?/i =~ msg.body
  end

  def negative?(msg)
    return /n(o)?/i =~ msg.body
  end

end
