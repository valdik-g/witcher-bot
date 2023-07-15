class Passport < ApplicationRecord
  has_and_belongs_to_many :kvests
  has_and_belongs_to_many :buffs
  has_and_belongs_to_many :titles
  has_one :user
  has_one :user_prerecording, inverse_of: 'passport'

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
      return_buttons(user, bot, chat_id, 'Неверный ввод, повторите команду снова')
    end
  end
end