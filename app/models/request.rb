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
    state :awaiting_address, :awaiting_issue, :check_need_responder, :await_description, :pending_responder, :responder_assigned, :pending_feedback, :resolved, :unresolved

    event :process do
      transition from: :new_request, to: :awaiting_address
      transition from: :awaiting_address, to: :awaiting_issue
      transition from: :check_need_responder, to: :awaiting_desc
      transition from: :pending_responder, to: :responder_assigned
      transition from: :responder_assigned, to: :awaiting_feedback
    end


  end


end
