# frozen_string_literal: true

# module for level up battle pass
module LevelUpSumBp
    def choose_level_up_sum_bp_passports(message, bot, user)
      if user.admin
        output_all_passports(bot, message.chat.id)
        bot.api.send_message(chat_id: message.chat.id,
                             text: 'Выберите тех, кому повысить уровень летнего бп:',
                             reply_markup: cancel_markup)
        user.update(step: 'level_up_sum_passport')
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
      end
    end
  
    def level_up_sum_passport(message, bot, user)
      message.text.split(' ').each do |passport_id|
        passport = Passport.find_by(id: passport_id)
        next unless passport
  
        next_level = passportsum_.bp_level + 1
        passport.update(sum_bp_level: passport.sum_bp_level + 1)
        bot.api.send_message(chat_id: message.chat.id,
                             text: "Уровень летнего боевого пропуска для игрока #{passport.nickname} повышен до #{passport.reload.sum_bp_level}")
        unless passport.user.nil?
          bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                               text: "Поздравляем, ваш уровень летнего боевого пропуска повышен до #{passport.sum_bp_level}")
        end
      end
  
      return_buttons(user, bot, message.chat.id, "Уровень боевого пропуска повышен")
    end
  end
  