# frozen_string_literal: true

# module for getting passport of the best player
module GetBest
  def get_best(message, bot, user)
    passport = Passport.order(Arel.sql('CAST(level as integer) DESC')).first
    bot.api.send_message(chat_id: message.chat.id,
                         text: "\xF0\x9F\x94\xA5 Паспорт лучшего игрока \xF0\x9F\x94\xA5")
    bot.api.send_message(chat_id: message.chat.id,
                         text: output_passport(passport.id, user))
  end
end
