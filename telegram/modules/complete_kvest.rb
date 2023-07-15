# frozen_string_literal: true

# module for add completed kvests to users
module CompleteKvest
  def complete_kvest(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Выберите номер паспорта игрока, выполнившего квест',
                           reply_markup: cancel_markup)
      user.update(step: 'input_passport_number')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_passport_number(message, bot, user)
    kvests_message = Kvest.all.map { |kvest| "#{kvest.id}: #{kvest.kvest_name}\n"}.join
    bot.api.send_message(chat_id: message.chat.id, text: kvests_message)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите номер(а) выполненного квеста')
    user.update(step: 'input_kvest_number')
    message.text
  end

  def input_kvest_number(message, bot, user, passport_number, repeat=false)
    function = repeat ? 'add_kvest' : 'add_notrepeated_kvest'
    kvests_number = message.text.split(' ')
    passport_number.split(' ').map do |pass_number|
      passport = Passport.find_by(id: pass_number)
      next unless passport

      kvests_number.map do |number|
        kvest = Kvest.find(number)
        next unless kvest
        send(function, kvest, passport, message, bot)
      end
    end
    return_buttons(user, bot, message.chat.id, 'Квесты проставлены игрокам')
  end

  private

  def add_reward(kvest, passport)
    new_crons = kvest.crons_reward + passport.crons
    new_level = (kvest.level_reward + passport.level.to_i).to_s
    new_addkvest = kvest.additional_kvest + passport.additional_kvest
    new_repkvest = kvest.kvest_repeat + passport.kvest_repeat
    passport.update(crons: new_crons, level: new_level, additional_kvest: new_addkvest, kvest_repeat: new_repkvest)
    passport.titles << Title.find_by(id: kvest.title_id) unless kvest.title_id.nil?
    unless kvest.additional_reward.downcase == 'нет'
      passport.update(inventory: passport.inventory + kvest.additional_reward + "\n")
    end
    passport.kvests << kvest
  end

  def add_kvest(kvest, passport, message, bot)
    add_reward(kvest, passport)
    bot.api.send_message(chat_id: message.chat.id,
                        text: "Квест #{kvest.kvest_name} успешно выполнен игроком #{passport.nickname}")
    unless User.find_by(passport_id: passport.id).nil?
      bot.api.send_message(chat_id: User.find_by(passport_id: passport.id).telegram_id,
                          text: "Поздравляем, ваш уровень повышен до #{passport.level}")
    end
  end

  def add_notrepeated_kvest(kvest, passport, message, bot)
    unless passport.kvests.include? kvest
      add_kvest(kvest, passport, message, bot)
    else
      bot.api.send_message(chat_id: message.chat.id,
        text: "Квест #{kvest.kvest_name} уже выполнен игроком #{passport.nickname}, пропускаем")
    end
  end
end
