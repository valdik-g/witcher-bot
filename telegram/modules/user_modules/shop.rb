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
      output_cost_types(message, bot, user)
    when 'Удалить предмет'
      choose_item_to_remove(message, bot, user)
    when 'Изменить количество'
      output_item_to_change_count(message, bot, user)
    when 'Очистить магазин'
      Product.delete_all
      return_buttons(user, bot, message.chat.id, 'Магазин очищен')
    end
  end

  def output_cost_types(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите тип стоимости', reply_markup: cost_markup)
    user.update(step: 'choose_cost_type')
  end

  def choose_cost_type(message, bot, user)
    case message.text
    when 'Кроны'
      @cost_type = 'crons'
    when 'Рубли'
      @cost_type = 'rubles'
    when 'Предмет в инвентаре'
      bot.api.send_message(chat_id: message.chat.id, text: 'В стоимости необходимо указать номер предмета в инвентаре' \
                                                           'и через пробел его количество. Пример: 12 3; 14 2')
      bot.api.send_message(chat_id: message.chat.id, text: Inventory.all.map { |i| "#{i.id}: #{i.item_name}\n" }.join)
      @cost_type = 'inventory'
    end
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите название предмета, стоимость, ' \
                                                         'и количество через запятую', reply_markup: cancel_markup)
    user.update(step: 'choose_item_type')
    @cost_type
  end

  def choose_item_type(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Введите тип предмета', reply_markup: type_markup)
    user.update(step: 'additional_cost')
    message.text.split(',')
  end

  def additional_cost(message, bot, user)
    bot.api.send_message(chat_id: message.chat.id, text: 'Дополнительная стоимость?(Формат: 20 крон, 3 чая)',
                         reply_markup: no_markup)
    user.update(step: 'add_item_to_shop')
    message.text
  end

  def add_item_to_shop(message, bot, user, product_values)
    additional_cost = message.text == 'Нет' ? '' : message.text
    item, cost, quantity, cost_type, item_type = product_values
    @product = Product.create(item: item, cost: cost, quantity: quantity, cost_type: cost_type, item_type: item_type,
                              additional_cost: additional_cost)
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
      return_buttons(user, bot, message.chat.id, 'Предмет удален') 
    else
      return_buttons(user, bot, message.chat.id, 'Такого предмета нет. Повторите команду')
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
      return_buttons(user, bot, message.chat.id, 'Такого предмета нет. Повторите команду')
    end
  end

  # def output_shop(message, bot, user)
  #   crons_message = Product.where(cost_type: 'crons').map do |p|
  #     "#{p.id}: #{p.item} - #{p.cost}\xF0\x9F\xAA\x99. " \
  #                         "Кол-во: #{p.quantity}.\n"
  #   end.join
  #   rubles_message = Product.where(cost_type: 'rubles').map do |p|
  #     "#{p.id}: #{p.item} - #{p.cost} рублей. " \
  #                         "Кол-во: #{p.quantity}.\n"
  #   end.join
  #   inventory_message = Product.where(cost_type: 'inventory').map do |p|
  #     total_cost = p.cost.split("; ").map do |ic|
  #                    item_id, cost = ic.split(' ')
  #                    "#{Inventory.find_by(id: item_id).item_name} - #{cost} штук(и)\n"
  #                  end.join
  #     "#{p.id}: #{p.item}\nСтоимость:\n#{total_cost}\n"
  #   end.join
  #   shop_message = shop_message(crons_message, rubles_message, inventory_message)
  #   if shop_message.empty?
  #     bot.api.send_message(chat_id: message.chat.id, text: 'Магазин пуст. Возвращайтесь позже')
  #   else
  #     bot.api.send_message(chat_id: message.chat.id, text: "Магазин:\n#{shop_message}", reply_markup: cancel_markup)
  #     bot.api.send_message(chat_id: message.chat.id, text: 'Выберите предмет, вводите цифрой')
  #     user.update(step: 'input_item_id')
  #   end
  # end

  def output_shop(message, bot, user, i=0)
    grouped_products = Product.all.group_by(&:item_type)
    shop_message = shop_message(grouped_products, i)
    bot.api.send_message(chat_id: user.telegram_id, text: shop_message, 
                         reply_markup: output_shop_markup)
    bot.api.send_message(chat_id: message.chat.id, text: 'Выберите предмет, вводите цифрой', 
                         reply_markup: cancel_markup)
    user.update(step: 'input_item_id')
  end

  def output_shop_edit(message, bot, user, i=0)
    begin
      grouped_products = Product.all.group_by(&:item_type)
      i = 0 if i >= grouped_products.size
      i = grouped_products.size + i if i < 0
      shop_message = shop_message(grouped_products, i)
      bot.api.edit_message_text(chat_id: user.telegram_id, text: shop_message, message_id: message.message.message_id,
                                reply_markup: output_shop_markup)
    rescue
      p 'Nothing changed'
    end
    return i
  end

  def input_item_id(message, bot, user)
    item = Product.find_by(id: message.text)
    current_buyer = user.passport
    if item.nil?
      return_buttons(user, bot, message.chat.id, 'Такого предмета нет, повторите ввод')
    else
      case item.cost_type
      when 'crons'
        if item.cost.to_i < current_buyer.crons
          buy_item(bot, item, current_buyer)
          return_buttons(user, bot, message.chat.id, 'Предмет приобретен')
        else
          return_buttons(user, bot, message.chat.id, 'Предмет не приобретен, недостаточно крон')
        end
      when 'rubles'
        send_message_for_admin(bot, "#{current_buyer.nickname} желает приобрести #{item.item}")
        return_buttons(user, bot, message.chat.id, 'Уведомление отправлено Анри Вилу')
      when 'inventory'
        if item.item.include?('Эликсир')
          i = Inventory.find_by(item_name: item.item)
          if PassportsInventory.find_by(inventory_id: i.id, passport_id: current_buyer.id)
            return_buttons(user, bot, message.chat.id, 'Данный эликсир уже приобретен')
          end
        end
        if can_purchase?(item.cost, current_buyer)
          purchase_for_items(item, current_buyer)
          return_buttons(user, bot, message.chat.id, 'Предмет приобретен')
        else
          return_buttons(user, bot, message.chat.id, 'Недостаточно предметов в инвентаре')
        end
      end
    end
  end

  private

  def shop_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: shop_buttons.map do |button|
      Telegram::Bot::Types::KeyboardButton.new(text: button)
    end)
  end

  def shop_buttons
    ['Добавить предмет', 'Удалить предмет', 'Изменить количество', 'Очистить магазин']
  end

  def cost_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: cost_buttons.map do |button|
      Telegram::Bot::Types::KeyboardButton.new(text: button)
    end)
  end

  def cost_buttons
    ['Кроны', 'Рубли', 'Предмет в инвентаре']
  end

  def type_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: type_buttons.map do |button|
      Telegram::Bot::Types::KeyboardButton.new(text: button)
    end)
  end

  def output_shop_markup
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: '<<', callback_data: 'shop_prev'),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: '>>', callback_data: 'shop_next')        
      ]
    ])
  end

  def type_buttons
    ["🔩 Ⳝⲁⲣ «Ⲣⲃⲁⲏыύ ⳝⲟⲗⲧ» 🍻", "🍶Эⲗυⲕⲥυⲣы", "🥋Ⲙⲉⲣⳡ Цⲉⲭⲁ", "⚒️ Ⲩⲥⲗⲩⲅυ ⲕⲣⲁⲥⲏⲟⲗюⲇⲟⲃ", "🗿Ⳅⲉⲣⲣυⲕⲁⲏⲥⲕυⲉ ⲧⲟⲃⲁⲣы",
     "⚔️ Ⲡⲣⲟⲕⲁⳡⲕⲁ ⲡⲉⲣⲥⲟⲏⲁⲯⲁ", "📜 Ⲙⲁⲅυⳡⲉⲥⲕⲁя ⲗⲁⲃⲕⲁ"]
  end

  def send_message_for_admin(bot, text)
    bot.api.send_message(chat_id: 822281212, text: text) # main admin telegram_id 612_352_098
  end

  def buy_item(bot, product, current_buyer)
    case product.item
    when 'Свиток повтора' 
      current_buyer.update(additional_kvest: current_buyer.additional_kvest + 1)
    when 'Свиток доп квеста'
      current_buyer.update(kvest_repeat: current_buyer.kvest_repeat + 1)
    when 'Свиток вызова'
      current_buyer.update(kvest_repeat: current_buyer.kvest_call + 1)
    else
      item = Inventory.find_or_create_by(item_name: product.item)
      passport_inventory = PassportsInventory.find_or_create_by(passport_id: current_buyer.id, inventory_id: item.id)
      passport_inventory.update(quantity: passport_inventory.quantity + 1)
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

  def purchase_for_items(product, current_buyer)
    product.cost.split("; ").each do |ic|
      item_id, cost = ic.split(' ')
      passport_inventory = PassportsInventory.find_by(passport_id: current_buyer.id, inventory_id: item_id)
      passport_inventory.update(quantity: passport_inventory.quantity - cost.to_i)
    end
    item = Inventory.find_or_create_by(item_name: product.item)
    PassportsInventory.create(passport_id: current_buyer.id, inventory_id: item.id, quantity: 1)
  end

  def can_purchase?(items, current_buyer)
    items.split("; ").each do |ic|
      item_id, cost = ic.split(' ')
      passport_inventory = PassportsInventory.find_by(passport_id: current_buyer.id, inventory_id: item_id)
      return false unless passport_inventory
      return false if passport_inventory.quantity < cost.to_i
    end
    true
  end

  # def shop_message(crons_message, rubles_message, inventory_message)
  #   crons_message = "Предметы за кроны\xF0\x9F\xAA\x99:\n" +  crons_message + "\n" unless crons_message.to_s.empty?
  #   rubles_message = "Предметы за чеканные:\n" + rubles_message + "\n" unless rubles_message.to_s.empty?
  #   inventory_message = "Предметы для крафта:\n" + inventory_message unless inventory_message.to_s.empty?
  #   crons_message.to_s + rubles_message.to_s + inventory_message.to_s
  # end

  def shop_message(grouped_products, i=0)
    group_name, group_items = grouped_products.keys[i], grouped_products.values[i]
    groups_message = group_items.group_by(&:cost_type).map do |group_cost|
      cost_type, items = group_cost
      items.map do |p|
        case cost_type
        when 'crons'
          "#{p.id}: #{p.item} - #{p.cost}\xF0\x9F\xAA\x99. #{output_additional_cost(p)}Кол-во: #{p.quantity}.\n"
        when 'rubles'
          "#{p.id}: #{p.item} - #{p.cost} рублей. #{output_additional_cost(p)}Кол-во: #{p.quantity}.\n"
        when 'inventory'
          total_cost = p.cost.split("; ").map do |ic|
                         item_id, cost = ic.split(' ')
                         "#{Inventory.find_by(id: item_id).item_name} - #{cost} штук(и)\n"
                       end.join
          "#{p.id}: #{p.item}\nСтоимость:\n#{total_cost}#{output_additional_cost(p)}}Кол-во: #{p.quantity}.\n"
        end
      end.join
    end.join
    "🛒 Ⲙⲁⲅⲁⳅυⲏ Цⲉⲭⲁ:\n\n\n#{group_name}\n\n#{groups_message}"
  end

  def output_additional_cost(product)
    product.additional_cost.empty? ? '' : "Доп стоимость:\n#{product.additional_cost.split(',').join("\n")}." 
  end
end
