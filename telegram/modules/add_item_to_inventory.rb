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
    item_message = "Выберите предмет, который необходимо добавить игроку/игрокам\n" \
                   'Список существующих предметов приведен ниже' \
                   '(пиши название предмета, если его нет в списке, просто пиши название нового предмета)'
    bot.api.send_message(chat_id: message.chat.id, text: item_message)
    bot.api.send_message(chat_id: message.chat.id, text: Inventory.all.collect(&:item_name).join("\n"))
    user.update(step: 'choose_item_quantity')
    message.text
  end

  def choose_item_quantity(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите количество предмета')
    user.update(step: 'add_item_to_inventory')
    message.text
  end

  def add_item_to_inventory(message, bot, user, players, item_name)
    item = Inventory.find_or_create_by(item_name: item_name)
    players.split(' ').map do |pass_number|
      passport = Passport.find_by(id: pass_number)
      next unless passport

      passport_inventory = PassportsInventory.find_or_create_by(passport_id: pass_number, inventory_id: item.id)
      passport_inventory.update(quantity: passport_inventory.quantity + message.text.to_i)
    end
    return_buttons(user, bot, message.chat.id, 'Предметы добавлены игрокам')
  end
end
