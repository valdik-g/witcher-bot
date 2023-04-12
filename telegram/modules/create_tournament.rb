module CreateTournament

  # yes_no_kb = [
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Да'),
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Нет')
  # ]
  # reward_types_kb = [
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Кроны'),
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Свитки повтора'),
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Свитки доп квеста')
  # ]
  # reward_types_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: admin_kb, resize_keyboard: true)

  # tournament_markup = [
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Случайное распределение пар'),
  #   Telegram::Bot::Types::KeyboardButton.new(text: 'Вручную')
  # ]
  
  # def get_pairs
  #   pair_list = ''
  #   pair_id_list = ''
  #   while members.length.positive?
  #     sample = members.sample
  #     pair1 = Passport.find(sample)
  #     members.delete(sample)
  #     if members.length.positive?
  #       sample = members.sample
  #       pair2 = Passport.find(sample)
  #       members.delete(sample)
  #       pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname}" \
  #       " - #{pair2.titles.find(pair2.main_title_id)} #{pair2.nickname} \n"
  #       pair_id_list += "#{pair1.id} #{pair2.id}\n"
  #     else
  #       pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname} \n"
  #     end
  #   end
  #   Tournament.last.update(pairs: pair_id_list)
  # end
  
  # def create_tournament_choise(pair)
  #   fight_order_kb = [
  #     Telegram::Bot::Types::KeyboardButton.new(text: pair[0]),
  #     Telegram::Bot::Types::KeyboardButton.new(text: pair[1])
  #   ]
  #   Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: fight_order_kb)
  # end

  #   def create_tournamet
  #       if user.admin
  #           bot.api.send_message(chat_id: message.chat.id, text: 'Введите тип награды',
  #                               reply_markup: reward_types_markup)
  #           user.update(step: 'input_tournament_reward_type')
  #         else
  #           bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
  #         end
  #   end
     # when 'input_tournament_reward_type'
              #   @reward_type = message.text
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Сколько?', reply_markup: cancel_markup)
              #   user.update(step: 'input_reward_count')
              # when 'input_reward_count'
              #   @reward_count = message.text
              #   if @tournament.nil?
              #     @tournament = Tournament.create(@reward_type: @reward_count)
              #   else
              #     Tournament.last.update(@reward_type: @reward_count)
              #   end
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Еще награды?', reply_markup: yes_no_kb)
              #   user.update(step: 'input_reward_repeat')
              # when 'input_reward_repeat'
              #   if message.text == 'Да'
              #     bot.api.send_message(chat_id: message.chat.id, text: 'Введите тип награды', reply_markup: reward_types_markup)
              #     user.update(:step => 'input_tournament_reward_type')
              #   else
              #     bot.api.send_message(chat_id: message.chat.id, text: 'Введите участников турнира', reply_markup: cancel_markup)
              #     output_all_passports(bot, message.chat.id)
              #     user.update(:step => 'input_tournament_members')
              #   end
              # when 'input_tournament_members'
              #   Tournament.last.update(:members => message.text)
              #   Tournament.last.members.each { |id|  bot.api.send_message(chat_id: User.find_by(:passport_id => id).telegram_id, text: 'Вы участник турнира, приготовьтесь!')}
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Выберите распредление участников', reply_markup: tournament_markup)
              #   user.update('input_distribution')
              # when 'input_distribution'
              #   members = Tournament.last.members
              #   if message.text == 'Случайное распределение пар'
              #     pairs_list = ''
              #     pair_id_list = ''
              #     while members.length.positive?
              #       sample = members.sample
              #       pair1 = Passport.find(sample)
              #       members.delete(sample)
              #       if members.length > 0
              #         sample = members.sample
              #         pair2 = Passport.find(sample)
              #         members.delete(sample)
              #         pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname}" \
              #         " - #{pair2.titles.find(pair2.main_title_id)} #{pair2.nickname} \n"
              #         pair_id_list += "#{pair1.id} #{pair2.id}\n"
              #       else
              #         pair_list += "#{pair1.titles.find(pair1.main_title_id)} #{pair1.nickname} \n"
              #       end
              #     end
              #     Tournament.last.update(:pairs => pair_id_list)
              #     Tournament.last.members.split(' ').each do |member|
              #       bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: "Список пар: ")
              #       bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: pair_list)
              #       @pair = pair_id_list.split('\n')[0].split(' ')
              #       @pair[0] = @pair[0] + ":" + Passport.find(@pair[0]).nickname
              #       @pair[1] = @pair[1] + ":" + Passport.find(@pair[1]).nickname
              #       User.find_by(:passport_id => member).update(:step => 'fights') if pair.include?(member)
              #     end
              #   else
              #     # TODO write user pairs creation
              #   end
              #   #TODO do something with buttons
              #   create_tournament_choise(@pair)
              #   bot.api.send_message(chat_id: message.chat.id, text: 'Введите победителя')
              #   user.update('fight_winner')
              # when 'fight_winner'
              #   Tournament.last.update(:pairs => Tournament.last.pairs.split("\n").drop(1).join("\n"))
              #   loser = message.text  # Find id of loser
              #   members = Tournament.last.members
              #   members.split(" ").delete(loser)
              #   Tournament.last.update(members: members.join(" "))
              #   if members.length == 1
              #     user.update(:step => nil)
              #   else
              #     get_pairs() if Tournament.last.pairs.empty?
              #     bot.api.send_message(chat_id: message.chat.id, text: 'Введите победителя', reply_markup: create_tournament_choise(Tournament.last.pairs.split("\n")[0]))
              #   end
              # when 'fights'
              # fight_order_kb = [
              #   Telegram::Bot::Types::KeyboardButton.new(text: Tournament.last.pairs.split("\n")[Tournament.last.iteration]),
              #   Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
              # ]
              # feedback_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: feedback_kb, resize_keyboard: true)
              # Tournament.last.members.split(' ').excluding().each do |member|
              #   bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: "Ваша ставка," \
              #   "на кого и сколько (обязательная ставка 1 крона, в случае отсутствия выбора, ИИ этого крутого бота сделает все за вас)?")
              #   bot.api.send_message(chat_id: User.find_by(:passport_id => member).telegram_id, text: pair_list)
              # end
end