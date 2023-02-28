class Passport < ApplicationRecord
  has_and_belongs_to_many :kvests
  has_and_belongs_to_many :titles
  belongs_to :user, inverse_of: 'passport', optional: true
end