# frozen_string_literal: true

# module for assign titles for witchers
module AddItemToInventory
  def choose_players_inventory(message, bot, user)
    if user.admin
      output_all_passports(bot, message.chat.id)
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Выберите тех, кому необходимо добавить предмет',
                           reply_markup: cancel_markup)
      user.update(step: 'choose_item_to_add')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def choose_item_to_add(message, bot, user) 
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите предмет, который необходимо добавить игроку/игрокам')
    user.update(step: 'add_item_to_inventory')
    message.text
  end

  def add_item_to_inventory(message, bot, user, players)
    players.split(' ').map do |pass_number|
      passport = Passport.find_by(id: pass_number)
      next unless passport

      passport.update(inventory: passport.inventory + message.text + "\n")
    end
    return_buttons(user, bot, message.chat.id, 'Предметы добавлены игрокам')
  end
end
