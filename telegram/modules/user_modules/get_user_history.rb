# frozen_string_literal: true

# module for getting any passports history
module GetUserHistory
    def choose_passport_to_show_history(message, bot, user)
      output_passport_with_history(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Выберите номер паспорта игрока', reply_markup: cancel_markup)
      user.update(step: 'input_player_passport_number_for_history')
    end
  
    def input_player_passport_number_for_history(message, bot, user)
      number = message.text
      passport = Passport.find_by(number)
      history_message = if passport
        passports_history(passport, user)
      else
        'Такого паспорта нет, повторите команду'
      end
      return_buttons(user, bot, message.chat.id, history_message)
    end

    private

    def output_passport_with_history(bot, chat_id)
      passports_with_history = Passport.where("history <> ''").map { |p| "#{p.id}: #{p.nickname}\n" }.join
      bot.api.send_message(chat_id: chat_id, text: passports_message)
    end

    def passports_history(passport)
       return "История игрока #{passport.nickname} пуста" if passport.history.empty?

      "История игрока #{passport.nickname}\n\n#{passport.history}"
    end
  end
  