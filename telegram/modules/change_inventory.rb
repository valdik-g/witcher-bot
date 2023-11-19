module ChangeInventory
  def choose_inventory_passport(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите пользователя для изменения инвентаря', 
                         reply_markup: cancel_markup)
    output_all_passports(bot, message.chat.id)
    user.update(step: 'choose_inventory_record')
  end

  def choose_inventory_record(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите запись для изменения:')
    inventories = PassportsInventory.select("passports_inventories.id, inventories.item_name, 
                                             passports_inventories.quantity")
                                    .joins(:inventory).where(passport_id: message.text.to_i)  
    return_buttons(user, bot, message.chat.id, 'У пользователя нет предметов в инвентаре') unless inventories

    output = inventories.map {|c| "#{c.id}: #{c.item_name}, #{c.quantity} шт."}.join("\n")
    bot.api.send_message(chat_id: message.chat.id, text: output)
    user.update(step: 'choose_inventory_field')
  end

  def choose_inventory_field(message, bot, user)
    passport_inventory = PassportsInventory.find_by(id: message.text.to_i)
    return_buttons(user, bot, message.chat.id) unless passport_inventory

    bot.api.send_message(chat_id: message.chat.id, text: "Введите новое значения для поля")
    user.update(step: 'change_value_field')
    passport_inventory
  end

  def change_value_field(message, bot, user, inventory)
    inventory.update(quantity: message.text.to_i)
    return_buttons(user, bot, message.chat.id, 'Значение изменено')
  end
end