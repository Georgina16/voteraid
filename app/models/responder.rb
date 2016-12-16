class Responder < ApplicationRecord
  has_many :requests, inverse_of: :responder
  geocoded_by :full_street_address   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates

  validates :fname,:lname, presence: true
  validates :phone, presence: true, format: { with: /\+1[0-9]{10}/ , message: "Please provide number in format +1XXXYYYZZZZ"}, uniqueness: true
  validates :email, presence: true, format: { with: /@/ }
  validates :address, :city, :state, :zip, presence: true

  def full_street_address
    return "#{address}, #{city}, #{state}"
  end
end
