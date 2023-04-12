module CreateKvest
  def create_kvest(message, bot, user, cancel_markup)
    if user.admin
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите название квеста:',
                          reply_markup: cancel_markup)
      user.update(step: 'input_kvest_name')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_kvest_name(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество крон:')
    user.update(step: 'input_crons_reward')
    message.text
  end

  def input_crons_reward(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id,
                        text: 'Введите количество уровней, получаемых за выполнение квеста:')
    user.update(step: 'input_level_reward')
    message.text
  end

  def input_level_reward(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите получаемый титул:')
    user.update(step: 'input_title_reward')
    message.text
  end

  def input_title_reward(message, bot, user, kvest_name)
    title_reward = message.text
    if title_reward != 'Нет' && Title.find_by(title_name: title_reward).nil?
      Title.create(title_name: title_reward, description: "Выдается за выполнение квеста #{kvest_name}")
    end
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество выдаваемых доп квестов (0 если нет):')
    user.update(step: 'input_addkvest_reward')
    message.text
  end

  def input_addkvest_reward(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество свитков повтора (0 если нет):')
    user.update(step: 'input_repeat_kvest_reward')
    message.text
  end

  def input_repeat_kvest_reward(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите дополнительную награду:')
    user.update(step: 'input_additional_reward')
    message.text
  end

  def input_additional_reward(message, bot, user, rewards)
    Kvest.create!(kvest_name: rewards[:kvest_name], crons_reward: rewards[:crons_reward], 
                  level_reward: rewards[:level_reward], 
                  title_id: rewards[:title_reward] == 'Нет' ? nil :  Title.find_by(title_name: rewards[:title_reward]).id,
                  additional_kvest: rewards[:addkvest], kvest_repeat: rewards[:repeat], 
                  additional_reward: message.text)
    return_buttons(user, bot, message.chat.id, 'Квест успешно создан')
  end
end