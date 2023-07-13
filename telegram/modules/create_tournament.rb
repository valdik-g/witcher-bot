module CreateTournament
  def create_tournamet(message, bot, user)
    if user.admin
        bot.api.send_message(chat_id: message.chat.id, text: 'Сколько крон за победу? (0 если нет)',
                            reply_markup: cancel_markup)
        user.update(step: 'input_tournament_crons')
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
      end
  end

  def input_tournament_crons(message, bot, user)
    Tournament.create(crons: message.text.to_i)
    bot.api.send_message(chat_id: message.chat.id, text: 'Сколько свитков доп кевестов')
    user.update(step: 'input_tournament_additional_kvest')
  end

  def input_tournament_additional_kvest(message, bot, user)
    Tournament.last.update(additional_kvest: message.text.to_i)
    bot.api.send_message(chat_id: message.chat.id, text: 'Сколько свитков повтора')
    user.update(step: 'input_tournament_repeat_kvest')
  end

  def input_tournament_repeat_kvest(message, bot, user)
    Tournament.last.update(repeat_kvest: message.text.to_i)
    bot.api.send_message(chat_id: message.chat.id, text: 'Доп награда (особые предметы)?')
    user.update(step: 'input_tournament_additional_reward')
  end

  def input_tournament_additional_reward(message, bot, user)
    Tournament.last.update(additional_reward: message.text)
    bot.api.send_message(chat_id: message.chat.id, text: 'Кто участвует в турнире?')
    output_all_passports(bot, message.chat.id)
    user.update(step: 'create_tournament_grid')
  end

  def create_tournament_grid(message, bot, user, members)
    pair_list = get_pairs(members)
    bot.api.send_message(chat_id: message.chat.id, text: 'Турнирная сетка:')
    bot.api.send_message(chat_id: message.chat.id, text: pair_list)
    fight(message, bot, user)
    user.update(step: 'choose_winner')
  end

  def get_pairs(members)
    pair_list = ''
    pair_id_list = ''
    Tournament.last.update(winners: '')
    while members.length.positive?
      sample = members.sample
      pair1 = Passport.find(sample)
      members.delete(sample)
      if members.length.positive?
        sample = members.sample
        pair2 = Passport.find(sample)
        members.delete(sample)
        title_1 = Title.find_by(id: pair1.main_title_id)
        title_2 = Title.find_by(id: pair2.main_title_id)
        title_name_1 = title_1 ? "#{title_1.title_name} " : ''
        title_name_2 = title_2 ? "#{title_2.title_name} " : ''
        pair_list += "#{title_name_1}#{pair1.nickname} - #{title_name_2}#{pair2.nickname} \n"
        pair_id_list += "#{pair1.id} #{pair2.id}\n"
      else
        title_1 = Title.find_by(id: pair1.main_title_id)
        title_name_1 = title_1 ? "#{title_1.title_name} " : ''
        pair_list += "#{title_name_1} #{pair1.nickname} \n"
        Tournament.last.update(winners: pair1.id.to_s)
      end
    end
    Tournament.last.update(pairs: pair_id_list)
    pair_list
  end

  def choose_winner(message, bot, user)
    t = Tournament.last
    p = Passport.find_by(id: message.text)
    new_pairs = t.pairs.split("\n")
    new_pairs.delete(t.pairs.split("\n")[0])
    t.update(pairs: new_pairs.join("\n"))
    if t.winners.blank?
      t.update(winners: message.text)
    else
      t.update(winners: "#{t.winners} #{message.text}")
    end
    if !t.winners.include?(' ') && t.pairs.empty?
      new_inventory = if p.inventory.blank? && t.additional_reward.blank?
        ''
      elsif p.inventory.blank? && !t.additional_reward.blank?
        t.additional_reward + "\n"
      else
        p.inventory + t.additional_reward + "\n"
      end
      p.update(crons: p.crons + t.crons, additional_kvest: p.additional_kvest + t.additional_kvest,
              kvest_repeat: p.kvest_repeat + t.repeat_kvest, inventory: new_inventory)
      return_buttons(user, bot, message.chat.id, 'Награда проставлена победителю, турнир окончен')
    else
      fight(message, bot, user)
    end
  end

  def fight(message, bot, user)
    t = Tournament.last
    if t.pairs.blank? && !t.winners.blank?
      pair_list = get_pairs(t.winners.split(' ')) 
      bot.api.send_message(chat_id: message.chat.id, text: 'Турнирная сетка:')
      bot.api.send_message(chat_id: message.chat.id, text: pair_list)
      # p.update(step: 'tournament_bet') unless pair_id_list.split("\n")[0].split(' ')
    end
    t = Tournament.last
    pair_list = t.pairs
    fighter1 = pair_list.split("\n")[0].split(' ')[0]
    fighter2 = pair_list.split("\n")[0].split(' ')[1]
    pair_message = "#{fighter1} #{Passport.find(fighter1).nickname} или #{fighter2} #{Passport.find(fighter2).nickname}"
    bot.api.send_message(chat_id: message.chat.id, text: "Кто победил? #{pair_message}\nВводите цифрой")
  end

  def tournament_bet()
  end

  # tournament_markup = [
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Случайное распределение пар'),
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Вручную')
  # ]
  

  
  # def create_tournament_choise(pair)
  #   fight_order_kb = [
  #     Telegram::Bot::Types::KeyboardButton.new(text: pair[0]),
  #     Telegram::Bot::Types::KeyboardButton.new(text: pair[1])
  #   ]
  #   Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: fight_order_kb)
  # end
end