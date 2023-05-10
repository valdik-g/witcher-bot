# frozen_string_literal: true

# module for ranking up users
module RankUp
  def rank_up(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Выберите того, кому необходимо поднять ранг',
                           reply_markup: cancel_markup)
      user.update(step: 'input_passport_rank')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_passport_rank(message, bot, user)
    ranks = ['Рекрут', 'Ученик', 'Кандидат', 'Младший ведьмак', 'Ведьмак']
    passport = Passport.find(message.text)
    next_rank = ranks.index(passport.rank) + 1
    passport.update(rank: ranks[next_rank])
    return_buttons(user, bot, message.chat.id, 'Ранг повышен')
    unless User.find_by(passport_id: passport.id).nil?
      bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                           text: "Поздравляем, ваш ранг повышен до #{ranks[next_rank]}")
    end
  end
end
