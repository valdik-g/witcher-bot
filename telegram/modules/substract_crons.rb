# frozen_string_literal: true

# module for substarcting crons from passports inventory
module SubstractCrons
  def substract_crons(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Кому спишем кроны?',
                           reply_markup: cancel_markup)
      user.update(step: 'input_passport_to_substract')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_passport_to_substract(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Сколько?')
    user.update(step: 'input_crons_to_substract')
    message.text
  end

  def input_crons_to_substract(message, bot, user, passport_id)
    crons = message.text
    passport = Passport.find_by(id: passport_id)
    if passport
      passport.update(crons: passport.crons - crons.to_i)
      begin
        if passport.user
          bot.api.send_message(chat_id: passport.user.telegram_id, 
                               text: crons.to_i > 0 ? "Цех списал с вас #{crons.to_i} крон" : "Цех начислил вам #{crons.to_i.abs} крон")
        end
      rescue => exception
        print("Пользователь #{passport.nickname} заблокировал бота")
      end
      return_buttons(user, bot, message.chat.id, 'Кроны списаны')
    else
      return_buttons(user, bot, message.chat.id, 'Нет такого паспорта')
    end
  end
end
