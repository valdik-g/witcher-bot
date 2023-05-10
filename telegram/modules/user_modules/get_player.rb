# frozen_string_literal: true

# module for getting any passport of players
module GetPlayer
  def get_player(message, bot, user)
    output_all_passports(bot, message.chat.id)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите номер паспорта игрока', reply_markup: cancel_markup)
    user.update(step: 'input_player_passport_number')
  end

  def input_player_passport_number(message, bot, user)
    number = message.text
    passport = Passport.find(number).nil? ? 'Некорректный ввод, повторите команду' : output_passport(number, user)
    return_buttons(user, bot, message.chat.id, passport)
  end
end
