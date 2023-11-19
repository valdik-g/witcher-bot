class Passport < ApplicationRecord
  has_and_belongs_to_many :kvests
  has_and_belongs_to_many :buffs
  has_and_belongs_to_many :titles
  has_many :passports_inventories
  has_many :inventories, through: :passports_inventories
  has_one :user
  has_one :user_prerecording, inverse_of: 'passport'
  after_create do |passport|
    UserPrerecording.create(passport_id: passport.id)
  end

  scope :with_inventory, -> { inventories.select('passports.*, passports_inventories.quantity') }

  def transfer_crons(crons, passport_id, chat_id, bot, user)
    to_transfer = Passport.find_by(id: passport_id)
    unless to_transfer.nil?
      if crons < 0 || crons > self.crons || passport_id == user.passport.id
        return_buttons(user, bot, chat_id, 'Э бля, так нельзя')
      else
        to_transfer.update(crons: to_transfer.crons + crons)
        self.update(crons: self.crons - crons)
        bot.api.send_message(chat_id: to_transfer.user.telegram_id, 
                             text: "Вам переведено #{crons} крон(ы)") if to_transfer.user
        return_buttons(user, bot, chat_id, 'Кроны переведены')
      end
    else
      return_buttons(user, bot, chat_id)
    end
  end

  def inventor
    self.inventories.select('inventories.item_name, passports_inventories.quantity').map do |item|
      item.quantity == 1 ? "#{item.item_name}\n" : " #{item.item_name} #{item.quantity} шт.\n"
    end.join
  end

  def add_item_to_inventory(item, quantity)
    Passport.
    Inventory.find_by(item_name: item)
  end
end