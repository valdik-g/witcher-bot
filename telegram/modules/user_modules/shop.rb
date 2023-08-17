# frozen_string_literal: true

# module for interactions users with show
module Shop
  def choose_update(message, bot, user)
    if user.admin
      bot.api.send_message(chat_id: message.chat.id, text: 'Выберите действие', reply_markup: shop_markup)
      user.update(step: 'update_shop')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end

  def update_shop(message, bot, user)
    case message.text
    when 'Добавить предмет'
      output_info_about_new_item(message, bot, user)
    when 'Удалить предмет'
      choose_item_to_remove(message, bot, user)
    when 'Изменить количество'
      output_item_to_change_count(message, bot, user)
    when 'Очистить магазин'
      Product.delete_all
      return_buttons(user, bot, message.chat.id, 'Магазин очищен')
    end
  end

  def output_info_about_new_item(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите название предмета, стоимость, ' \
                                                         'и количество через запятую', reply_markup: cancel_markup)
    user.update(step: 'add_item_to_shop')
  end

  def add_item_to_shop(message, bot, user)
    item, cost, quantity = message.text.split(',')
    Product.create(item: item, cost: cost, quantity: quantity)
    return_buttons(user, bot, message.chat.id, 'Предмет добавлен')
  end

  def choose_item_to_remove(message, bot, user)
    shop_message = Product.all.map { |p| "#{p.id}: #{p.item}\n" }.join
    bot.api.send_message(chat_id: message.chat.id, text: shop_message)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите предмет для удаления', reply_markup: cancel_markup)
    user.update(step: 'remove_item_from_shop')
  end
  
  def remove_item_from_shop(message, bot, user)
    product = Product.find_by(id: message.text)
    if product 
      product.delete
      return_buttons(user, bot, message.chat.id, 'Такого предмета нет. Повторите команду')
    else
      return_buttons(user, bot, message.chat.id, 'Предмет удален')
    end
  end

  def output_item_to_change_count(message, bot, user)
    shop_message = Product.all.map { |p| "#{p.id}: #{p.item}\n" }.join
    bot.api.send_message(chat_id: message.chat.id, text: shop_message)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите предмет для изменения количества, ' \
                                                         'а через запятую его новое количество', 
                                                   reply_markup: cancel_markup)
    user.update(step: 'change_quantity')
  end

  def change_quantity(message, bot, user)
    product_id, quantity = message.text.split(',')
    product = Product.find_by(id: product_id)
    if product
      product.update(quantity: quantity)
      return_buttons(user, bot, message.chat.id, "Количество предмета #{product.item} изменено до #{product.quantity}")
    else
      return_buttons(user, bot, message.chat.id, "Такого предмета нет. Повторите команду")
    end
  end

  def output_shop(message, bot, user)
    shop_message = Product.all.map { |p| "#{p.id}: #{p.item} - #{p.cost}\xF0\x9F\xAA\x99. " \
                                         "Кол-во: #{p.quantity}.\n" }.join
    if shop_message.empty?
      bot.api.send_message(chat_id: message.chat.id, text: 'Магазин пуст. Возвращайтесь позже')
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Магазин:\n" + shop_message, reply_markup: cancel_markup)
      bot.api.send_message(chat_id: message.chat.id, text: "Выберите предмет, вводите цифрой")
      user.update(step: 'input_item_id')
    end
  end

  def input_item_id(message, bot, user)
    item = Product.find_by(id: message.text)
    current_buyer = user.passport
    unless item.nil?
      if item.cost.to_i < current_buyer.crons
        buy_item(bot, item, current_buyer)
        return_buttons(user, bot, message.chat.id, 'Предмет приобретен')
      else
        return_buttons(user, bot, message.chat.id, 'Предмет не приобретен, недостаточно крон')
      end
    else
      return_buttons(user, bot, message.chat.id, 'Такого предмета нет, повторите ввод')
    end
  end

  private

  def shop_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: shop_buttons.map do |button|
      Telegram::Bot::Types::KeyboardButton.new(text:button)
    end)
  end

  def shop_buttons
    ['Добавить предмет', 'Удалить предмет', 'Изменить количество', 'Очистить магазин']
  end

  def send_message_for_admin(bot, text)
    bot.api.send_message(chat_id: 612352098, text: text) # main admin telegram_id
  end

  def buy_item(bot, product, current_buyer)
    case product.item
    when 'Свиток повтора'
      current_buyer.update(additional_kvest: current_buyer.additional_kvest + 1)
    when 'Свиток дополнительного квеста'
      current_buyer.update(kvest_repeat: current_buyer.kvest_repeat + 1)
    else
      current_buyer.update(inventory: current_buyer.inventory + "#{product.item}\n")
      if product.quantity == 1
        product.delete
        send_message_for_admin(bot, "Предмет #{product} закончился")
      else
        product.update(quantity: product.quantity - 1)
      end
    end
    current_buyer.update(crons: current_buyer.crons - product.cost.to_i)
    send_message_for_admin(bot, "#{current_buyer.nickname} приобрел(а) #{product.item}")
  end
end