# frozen_string_literal: true

# module for create battle pass kvest
module CreateBattlePassKvest
  def create_bp_kvest(message, bot, user)
    if user.admin
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество крон:', reply_markup: cancel_markup)
      user.update(step: 'input_bp_crons_reward')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def input_bp_crons_reward(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите получаемый титул:')
    user.update(step: 'input_bp_title_reward')
    message.text
  end

  def input_bp_title_reward(message, bot, user)
    title_reward = message.text
    if title_reward != 'Нет' && Title.find_by(title_name: title_reward).nil?
      Title.create(title_name: title_reward, description: "Титул за боевой пропуск")
    end
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество выдаваемых свитков повтора:')
    user.update(step: 'input_bp_kvestrepeat_reward')
    message.text
  end

  def input_bp_kvestrepeat_reward(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество выдаваемых свитков допа:')
    user.update(step: 'input_bp_addkvest_reward')
    message.text
  end

  def input_bp_addkvest_reward(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество свитков вызова:')
    user.update(step: 'input_bp_kvestcall_reward')
    message.text
  end

  def input_bp_kvestcall_reward(message, bot, user, rewards)
    BattlePassKvest.create!(crons_reward: rewards[:crons], 
      title_id: rewards[:title] == 'Нет' ? nil :  Title.find_by(title_name: rewards[:title]).id,
      additional_kvest: rewards[:add], 
      kvest_repeat: rewards[:repeat], 
      kvest_call: rewards[:call])
    return_buttons(user, bot, message.chat.id, 'Квест успешно создан')
  end
end