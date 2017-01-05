class Message < ApplicationRecord
  belongs_to :request, inverse_of: :messages
  validates :request_id, presence: true

end
