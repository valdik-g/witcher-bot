# frozen_string_literal: true

# module for changing every value in database
module ChangeRecord
  def change_record(message, bot, user, cancel_markup)
    if user.admin
      table_message = [User, Passport, Kvest, Title].map.with_index { |table, i| "#{i + 1}: #{table}\n".to_s }.join
      bot.api.send_message(chat_id: message.chat.id,
                           text: "#{table_message}Выберите таблицу для изменения:",
                           reply_markup: cancel_markup)
      user.update(step: 'choose_table')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def choose_table(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите запись для изменения')
    user.update(step: 'choose_record')
    active_table(bot, message, user)
  end

  def choose_record(message, bot, user, active_table)
    record = active_table.find(message.text)
    if record.nil?
      return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
    else
      bot.api.send_message(chat_id: message.chat.id,
                           text: "#{output_record(record)}\nВыберите поле для изменения")
      user.update(step: 'choose_field')
    end
    record
  end

  def choose_field(message, bot, user, record)
    if record.attributes.except('created_at', 'updated_at', 'id').include?(message.text)
      bot.api.send_message(chat_id: message.chat.id, text: 'Введите новое значение для поля')
      user.update(step: 'update_field_value')
    else
      return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
    end
    message.text
  end

  def update_field_value(message, bot, user, record, field)
    record.update(field => message.text)
    return_buttons(user, bot, message.chat.id, 'Запись обновлена')
  end

  private

  def active_table(bot, message, user)
    case message.text.to_i
    when 1 then choose_active_table(bot, message.chat.id, User, 'username')
    when 2 then choose_active_table(bot, message.chat.id, Passport, 'nickname')
    when 3 then choose_active_table(bot, message.chat.id, Kvest, 'kvest_name')
    when 4 then choose_active_table(bot, message.chat.id, Title, 'title_name')
    else
      return_buttons(user, bot, message.chat.id, 'Неверный ввод, повторите команду снова')
    end
  end

  def choose_active_table(bot, message, table, field)
    bot.api.send_message(chat_id: message, text: table.all.map { |t| "#{t.id}: #{t[field]}\n" }.join)
    table
  end
  
  def output_record(record)
    record.attributes.except('created_at', 'updated_at', 'id').map { |k, v| "#{k}: #{v}\n" }.join
  end
end
