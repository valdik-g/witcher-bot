class Title < ApplicationRecord
  has_and_belongs_to_many :passports
  before_destroy :update_passporst

  def update_passporst
    passports.each{ |passport| passport.update!(main_title_id: nil) }
  end
end