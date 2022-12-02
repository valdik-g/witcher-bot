require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'json'

require 'uri'
require 'net/http'
require 'openssl'

token = "5587814730:AAFci39iNXTgIeDLVTvKpCjULW2a94zbuP8"

witcher_name = ""
crons = 0
school = ""
level = 0
rank = ""
additional_kvest = false
elixirs = ""
description = ""
yes = ["да", "дп", "дв", "жа", "ла", "жв", "жп", "лп", "лв"]
no = ["нет", "неь", "неи", "нкт"]
passport = nil

kvest_name = ""
kvest_description = ""
crons_reward = 0
level_reward = 0
title_reward = "" 
additional_reward = ""

title_name = ""
title_description = ""

created_title = 0

passport_number = 0

tables = [User, Passport, Kvest, Title]

active_table = nil
record = nil
field = nil
field_array = []

passport_id = nil

update_field = ""

cancel_mkb = [
  Telegram::Bot::Types::KeyboardButton.new(text: 'Отмена')
]
cancel_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: cancel_mkb, resize_keyboard: true)

admin_kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: "Создать паспорт"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Создать квест"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Создать титул"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Выполнить квест"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Назначить титул"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Изменить запись"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Списать занятия"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Получить паспорт игрока"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Информация по игроку"),
  Telegram::Bot::Types::KeyboardButton.new(text: "Информация по всем абонементам")
]
admin_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: admin_kb, resize_keyboard: true)

def find_or_build_user(user_obj, chat_id)
  user = User.find_by(:telegram_id => user_obj.id)
  username = ""
  username += "#{user_obj.first_name}"
  username += " " if user_obj.last_name and user_obj.first_name 
  username += "#{user_obj.last_name}"
  user || User.create(:telegram_id => user_obj.id, :username => username)
end

def output_passport(passport_id, message, bot)
  passport = Passport.find_by(:id => passport_id)
  kvests = ""
  passport.kvests.map do |kvest|
    kvests += "-" + kvest.kvest_name + "\n"
  end
  long_kvest_record = Kvest.find_by(:id => passport.long_kvest_id)
  long_kvest = "Нет"
  long_kvest = Kvest.find_by(:id => passport.long_kvest_id).kvest_name if long_kvest_record
  additional_kvest = ""
  unless passport.additional_kvest == 0
    additional_kvest = "Свиток задания #{passport.additional_kvest} штук(и)\n"
  end
  kvests = "Кажется игрок еще не выполнил ни одного квеста!\n" if kvests.empty?
  title = ""
  if passport.main_title_id.nil?
    title = "Игрок еще не выбрал свой основной титул. Основной титул используется в сочетании с именем игрока, для вызова на турнир и в других ситуациях"
  else
    title = Title.find_by(:id => passport.main_title_id).title_name
  end
  inventory = passport.inventory.split(" ").join("\n")
  inventory += "\n" if passport.inventory.split(" ").length == 1
  passport_text = "\xF0\x9F\x97\xA1 ПЕРСОНАЖ:\n\n#{passport.nickname} #{passport.level} lvl
РАНГ- #{passport.rank}\n
\xF0\x9F\x8F\xB0 Школа: #{passport.school}\n
\xF0\x9F\x93\xAF Титул: #{title}\n
\xE2\x9D\x93 Проходит квест:\n#{long_kvest}\n#{"\n\xE2\x9D\x94 Пройденные квесты:\n#{kvests}" if User.find_by(:telegram_id => message.chat.id).admin && passport.id != User.find_by(:telegram_id => message.chat.id).passport_id}
\xF0\x9F\x93\x9C ОПИСАНИЕ:\n#{passport.description}\n
\xF0\x9F\x8E\x92 СУМКА:\nКроны - #{passport.crons}\xF0\x9F\xAA\x99
#{inventory}#{additional_kvest}#{"\n\xF0\x9F\x91\xBB Фамильяр:\n#{passport.familiar}\n" if passport.school == "Школа Змеи"}
\xF0\x9F\xA7\xAA Эликсиры:\n#{passport.elixirs.split(" ").join("\n")}"
  bot.api.send_message(chat_id: message.chat.id, text: passport_text)
end

remove_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

Telegram::Bot::Client.run(token) do |bot|
  Sidekiq::Cron::Job.create(
    name: "BirthdayCheck",
    cron: "00 12 * * * Europe/Minsk", 
    class: 'BirthdayCheckWorker'
  )

  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      begin
        user = find_or_build_user(message.from, message.chat.id)
          unless message.text.nil? && !message.text.empty? # && message.document.nil?
            case user.step
            when nil, 'start'
              case message.text
              when '/start', '/info'
                bot.api.send_message(chat_id: message.chat.id, text: "Привет, я бот клуба 'Свое Дело'!\nСписок моих команд находится внизу, удачи \xE2\x9D\xA4")
              when '/passport', "\xF0\x9F\x93\x9C Получить свой паспорт \xF0\x9F\x93\x9C"
                if user.passport_id.nil?
                  passport = Passport.find_by(:telegram_nick => user.username)
                  unless passport.nil?
                    user.update(:passport_id => passport.id)
                    user.update(:step => "input_bd")
                    bot.api.send_message(chat_id: message.chat.id, text: "Мы нашли ваш паспорт, однако предварительно нужно собрать немного ифнормации о вас\nВведите дату рождения(формат 03.09):")
                  else
                    bot.api.send_message(chat_id: message.chat.id, text: "Кажется ваш паспорт еще не существует, обратитесь к Анри Виллу")
                  end
                else
                  if Passport.find(user.passport_id).bd.empty?
                    user.update(:step => "input_bd")
                    bot.api.send_message(chat_id: message.chat.id, text: "Мы нашли ваш паспорт, однако предварительно нужно собрать немного ифнормации о вас\nВведите дату рождения(формат 03.09):")
                  else
                    output_passport(user.passport_id, message, bot)
                  end
                end
              when '/get_best', "\xF0\x9F\x94\x9D Получить паспорт лучшего игрока \xF0\x9F\x94\x9D"
                passport = Passport.order("level DESC, crons DESC").first
                bot.api.send_message(chat_id: message.chat.id, text: "\xF0\x9F\x94\xA5 Паспорт лучшего игрока \xF0\x9F\x94\xA5")
                output_passport(passport.id, message, bot)
              when '/get_history', "\xF0\x9F\x97\xBF Получить историю персонажа \xF0\x9F\x97\xBF"
                unless user.passport_id.nil?
                  history = Passport.find_by(:id => user.passport_id).history
                  history = "История вашего персонажа пуста" if history.empty?
                  bot.api.send_message(chat_id: message.chat.id, text: history)
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт",)
                end
              when '/update_history', "\xE2\x9C\x8D Изменить историю персонажа \xE2\x9C\x8D"
                unless user.passport_id.nil?
                  history = Passport.find_by(:id => user.passport_id).history
                  history = "История вашего персонажа пуста, самое время это исправить!\nВведите историю вашего персонажа" if history.empty?
                  bot.api.send_message(chat_id: message.chat.id, text: history)  
                  bot.api.send_message(chat_id: message.chat.id, text: "Введите новую историю", reply_markup: cancel_markup)
                  user.update(:step => "change_history")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт")
                end
              when '/get_kvests'
                unless user.passport_id.nil?
                  kvests = Passport.find_by(:id => user.passport_id).kvests
                  message_kvests = ""
                  kvests.each do |kvest|
                    message_kvests += "#{kvest["kvest_name"]}\n"
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: message_kvests)
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт")
                end
              when '/change_info'
                unless user.passport_id.nil?
                  passport = Passport.find_by(:id => user.passport_id)
                  bot.api.send_message(chat_id: message.chat.id, text: "Личная информация:\n1. Дата рождения: #{passport.bd}\n2. Почта: #{passport.mail}\n3. Телефон: #{passport.number}")
                  bot.api.send_message(chat_id: message.chat.id, text: "Что нужно изменить?\n1. Дата рождения\n2. Почта\n3. Телефон\nВводите цифрой", reply_markup: cancel_markup)
                  user.update(:step => "input_change_info_field")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт")
                end
              when '/create_passport', "Создать паспорт"
                if user.admin
                  bot.api.send_message(chat_id: message.chat.id, text: "Введите имя будующего ведьмака:")
                  user.update(:step => "input_name")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Ты как сюда залез?)")
                end
              when '/update_field', "Изменить запись"
                if user.admin
                  table_message = ""
                  tables.map.with_index do |table, i|
                    table_message += "#{i + 1}: #{table}\n".to_s
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: "#{table_message}Выберите таблицу для изменения:")
                  user.update(:step => "update_field")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Ты как сюда залез?)")
                end
              when '/create_kvest', "Создать квест"
                if user.admin
                  bot.api.send_message(chat_id: message.chat.id, text: "Введите название квеста:")
                  user.update(:step => "input_kvest_name")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Ты как сюда залез?)")
                end
              when '/kvest_done', "Выполнить квест"
                if user.admin
                  passports = Passport.all
                  passports_message = ""
                  passports.map do |passport|
                    passports_message += "#{passport.id}: #{passport.nickname}\n"
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                  bot.api.send_message(chat_id: message.chat.id, text: "Выберите номер паспорта игрока, выполнившего квест")
                  user.update(:step => "input_passport_number")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Ты как сюда залез?)")
                end
              when '/create_title', "Создать титул"
                if user.admin
                  bot.api.send_message(chat_id: message.chat.id, text: "Введите название титула")
                  user.update(:step => "input_title_name")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Ты как сюда залез?)")
                end
              when '/set_title', "Назначить титул"
                if user.admin
                  passports = Passport.all
                  passports_message = ""
                  passports.map do |passport|
                    passports_message += "#{passport.id}: #{passport.nickname}\n"
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                  bot.api.send_message(chat_id: message.chat.id, text: "Выберите номер паспорта игрока")
                  user.update(:step => "input_pasport_title")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Ты как сюда залез?)")
                end
              # when "/switch", "\xE2\x9E\xA1 Переключить меню \xE2\x9E\xA1", "\xE2\xAC\x85 Переключить меню \xE2\xAC\x85"
              #   if user.admin
              #     admin_kb = [
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Создать паспорт"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Создать квест"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Создать титул"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Выполнить квест"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Назначить титул"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Изменить запись"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Списать занятия"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Получить паспорт игрока"),
              #       Telegram::Bot::Types::KeyboardButton.new(text: "Получить информацию по абонементу"),
              #     ]
              #     admin_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: admin_kb, resize_keyboard: true)
              #     admin_markup = markup if message.text == "\xE2\xAC\x85 Переключить меню \xE2\xAC\x85"
              #     bot.api.send_message(chat_id: message.chat.id, text: "Функционал переключен", reply_markup: admin_markup)
              #   else
              #     bot.api.send_message(chat_id: message.chat.id, text: "Кажется тебе еще рановато сюда, приходи, когда вырастешь и закалишься в боях \xE2\x9A\x94")
              #   end
              when "/choose_title", "\xF0\x9F\x93\xAF Выбрать основной титул \xF0\x9F\x93\xAF"
                titles = Passport.find_by(:id => user.passport_id).titles if user.passport_id
                unless titles.nil?
                  titles_message = ""
                  titles.map do |title|
                    titles_message += "#{title.id}: #{title.title_name}\n"
                  end
                  bot.api.send_message(chat_id: message.chat.id, text: titles_message)
                  bot.api.send_message(chat_id: message.chat.id, text: "Выберите основной титул, вводите цифрой")
                  user.update(:step => "input_main_title")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Похоже у вас нет титулов")
                end
              when '/get_best_players', "Получить паспорт игрока"
                passports = Passport.all
                passports_message = ""
                passports.map do |passport|
                  passports_message += "#{passport.id}: #{passport.nickname}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                user.update(:step => "input_player_passport_number")
              when '/mem', "\xF0\x9F\xA4\xA1 Мемчик \xF0\x9F\xA4\xA1"
                meme = (Dir.entries("/home/cloud-user/witcher-bot/witcher-bot/telegram/memes").select {|f| !File.directory? f}).sample
                bot.api.sendPhoto(chat_id: message.chat.id, photo: Faraday::UploadIO.new("/home/cloud-user/witcher-bot/witcher-bot/telegram//memes/#{meme}", 'image/jpg'))
              when '/subscription', "\xF0\x9F\x92\xB3 Абонемент \xF0\x9F\x92\xB3"
                unless user.passport_id.nil?
                  if Passport.find_by(:id => user.passport_id).subscription.to_i> 1000
                    bot.api.send_message(chat_id: message.chat.id, text: "\xF0\x9F\x8E\x89 Поздравляю! \xF0\x9F\x8E\x89\nТы блатной")
                  else
                    sale_markup_buttons = [
                      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хочу 30%', url: 'tg://user?id=612352098')
                    ]
                    sale_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: sale_markup_buttons)
                    subscription = Passport.find_by(:id => user.passport_id).subscription
                    debt = Passport.find_by(:id => user.passport_id).debt
                    subs_message = "\xF0\x9F\x92\xB3 Абонемент: "
                    if subscription > 0 
                      subs_message += "Осталось #{Passport.find_by(:id => user.passport_id).subscription} посещений(я)"
                    else
                      subs_message += "Кажется у вас нет абонемента.\n Внизу есть кнопочка чтобы получить скидку в 30%, только \xF0\x9F\xA4\xAB"
                    end
                    subs_message += "\n\xF0\x9F\x92\xB0 Долг: "
                    if debt > 0 
                      subs_message += "#{debt}р"
                    else
                      subs_message += "Кажется у вас нет долгов, так держать! \xF0\x9F\x8E\x89"
                    end
                    bot.api.send_message(chat_id: message.chat.id, text: subs_message, reply_markup: sale_markup)
                  end
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Похоже к вам еще не привязан паспорт, используйте кнопку Получить свой паспорт")
                end
              when '/substract', "Списать занятия"
                bot.api.send_message(chat_id: message.chat.id, text: "Выберите тех, кто был на тренировке")
                passports = Passport.all
                passports_message = ""
                passports.map do |passport|
                  passports_message += "#{passport.id}: #{passport.nickname}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                user.update(:step => "input_substract")
              when '/subscription_info', 'Информация по игроку'
                bot.api.send_message(chat_id: message.chat.id, text: "Выберите паспорт", reply_markup: cancel_markup)
                passports = Passport.all
                passports_message = ""
                passports.map do |passport|
                  passports_message += "#{passport.id}: #{passport.nickname}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                user.update(:step => "input_abon_info")
              when 'Информация по всем абонементам'
                passports = Passport.all
                passports_message = ""
                passports.map do |passport|
                  passports_message += "#{passport.nickname}: #{passport.subscription}\n" if passport.subscription.to_i < 1000
                end
                bot.api.send_message(chat_id: message.chat.id, text: passports_message)
              when '/remove'
                reply_markup = user.admin ? admin_markup : remove_keyboard
                bot.api.send_message(chat_id: message.chat.id, text: "Кнопки убраны)", reply_markup:reply_markup)
              end
            # when "input_meme"
            #   file_info = bot.api.getFile(file_id: message.document.file_id)
            #   # https://api.telegram.org/file/bot#{token}/#{file_info.file_path}
            #   # url = URI("https://api.telegram.org/file/bot#{token}/#{file_info["result"]["file_path"]}")

            #   # http = Net::HTTP.new(url.host, url.port)
            #   # http.use_ssl = true

            #   # request = Net::HTTP::Get.new(url)
            #   # # request.body = "{'file_id': '#{message.document.file_id}'}"

            #   # response = http.request(request)
            #   # File.open(response.body, 'w') 
            #   # bot.api.sendPhoto(chat_id: message.chat.id, photo: file)
            #   # p file

            #   url = URI("https://api.telegram.org/file/bot#{token}/#{file_info["result"]["file_path"]}")
            #   http = Net::HTTP.new(url.host, url.port)
            #   http.use_ssl = true

            #   request = Net::HTTP::Get.new(url)
            #   response = http.request(request)
            #   file = response.read_body.read
            #   IO.copy_stream(response.read_body, '~/image.png')
            #   # file = # https://api.telegram.org/file/bot<token>/<file_path>
            #   bot.api.sendPhoto(chat_id: message.chat.id, photo: file)
            #   user.update(:step => nil)
            when 'input_name'
              witcher_name = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Введите школу:")
              user.update(:step => "input_school")
            when 'input_school'
              school = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Введите ранг")
              user.update(:step => "input_rank")
            when 'input_rank'
              rank = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Есть ли у будующего ведьмака доп квест(Введите количество, 0 если их нет):")
              user.update(:step => "input_additional_kvest")
            when 'input_additional_kvest'
              additional_kvest_info = message.text.downcase
              additional_kvest = true if yes.include?(additional_kvest_info)
              bot.api.send_message(chat_id: message.chat.id, text: "Введите эликсиры (Нет если эликсиры отстутствуют):")
              user.update(:step => "input_elixirs")
            when 'input_elixirs'
              elixirs = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Введите описание:")
              user.update(:step => "input_description")
            when 'input_description'
              description = message.text
              passport = Passport.create(:nickname => witcher_name, :crons => crons, :school => school,
                :level => level, :rank => rank, :additional_kvest => additional_kvest, :description => description,
                :elixirs => elixirs)
              bot.api.send_message(chat_id: message.chat.id, text: "Введите ник пользователя в телеграмм")
              user.update(:step => 'input_telegram_nick')
            when 'input_telegram_nick'
              telegram_nick = message.text
              passport.update(:telegram_nick => telegram_nick)
              update_user = User.find_by(:username => telegram_nick)
              update_user.update(:passport_id => passport.id) if update_user
              bot.api.send_message(chat_id: message.chat.id, text: "Запись создана")
              user.update(:step => nil)
            when 'change_user_description'
              description = message.text
              Passport.find_by(user_id: user.passport_id).update(:description => description)
              bot.api.send_message(chat_id: message.chat.id, text: "Описание успешно обновлено")
              user.update(:step => nil)
            when 'input_kvest_name'
              kvest_name = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Введите количество крон:")
              user.update(:step => "input_crons_reward")
            when 'input_crons_reward'
              crons_reward = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Введите количество уровней, получаемых за выполнение квеста:")
              user.update(:step => "input_level_reward")
            when 'input_level_reward'
              level_reward = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Введите получаемый титул:")
              user.update(:step => "input_title_reward")
            when 'input_title_reward'
              title_reward = message.text
              if title_reward != "Нет"
                Title.create(:title_name => title_reward, :description => "Выдается за выполнение квеста #{kvest_name}") unless Title.find_by(:title_name => title_reward)
              end
              bot.api.send_message(chat_id: message.chat.id, text: "Введите дополнительную награду:")
              user.update(:step => "input_additional_reward")
            when 'input_additional_reward'
              additional_reward = message.text
              title_reward_kvest = nil
              title_reward_kvest = Title.find_by(:title_name => title_reward).id unless title_reward == "Нет"
              kvest = Kvest.create!(:kvest_name => kvest_name, :crons_reward => crons_reward, :level_reward => level_reward, :title_id=> title_reward_kvest,
              :additional_reward => additional_reward)
              bot.api.send_message(chat_id: message.chat.id, text: "Квест успешно создан")
              user.update(:step => nil)
            when 'input_passport_number'
              passport_number = message.text
              kvests = Kvest.all
              kvests_message = ""
              kvests.map do |kvest|
                kvests_message += "#{kvest.id}: #{kvest.kvest_name}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: kvests_message)
              bot.api.send_message(chat_id: message.chat.id, text: "Введите номер(а) выполненного квеста")
              user.update(:step => 'input_kvest_number')
            when 'input_kvest_number'
              kvest_number = message.text
              kvests_number = kvest_number.split(" ")
              passports_number = passport_number.split(" ")
              passports_number.map do |pass_number|
                passport = Passport.find_by(:id => pass_number)
                if passport
                  kvests_number.map do |number|
                    kvest = Kvest.find_by(:id => number)
                    if kvest
                      unless passport.kvests.include? kvest
                        new_crons = kvest.crons_reward + passport.crons
                        new_level = kvest.level_reward + passport.level
                        passport.update(:crons => new_crons, :level => new_level)
                        passport.titles << Title.find_by(:id => kvest.title_id) unless kvest.title_id.nil?
                        passport.update(:inventory =>  passport.inventory + kvest.additional_reward) if kvest.additional_reward != "Нет"
                        passport.update(:inventory => passport.inventory + "\n") if kvest.additional_reward != "Нет"
                        passport.kvests << kvest
                        bot.api.send_message(chat_id: message.chat.id, text: "Квест #{kvest.kvest_name} успешно выполнен игроком #{passport.nickname}")
                      else
                        bot.api.send_message(chat_id: message.chat.id, text: "Квест #{kvest.kvest_name} уже добавлен #{passport.nickname}")
                      end
                    end
                  end
                end
              end
              user.update(:step => nil)
            when 'input_title_name'
              title_name = message.text
              bot.api.send_message(chat_id: message.chat.id, text: "Введите описание титула")
              user.update(:step => 'input_title_description')
            when 'input_title_description'
              title_description = message.text
              Title.create(:title_name => title_reward, :description => title_description)
              bot.api.send_message(chat_id: message.chat.id, text: "Титул #{title_name} создан")
              user.update(:step => nil)
            when 'change_history'
              if message.text == 'Отмена'
                reply_markup = user.admin ? admin_markup : remove_keyboard
                bot.api.send_message(chat_id: message.chat.id, text: "История не изменена", reply_markup: reply_markup)
              else
                history = message.text
                passport = Passport.find_by(:id => user.passport_id).update(:history => history)
                reply_markup = user.admin ? admin_markup : remove_keyboard
                bot.api.send_message(chat_id: message.chat.id, text: "История обновлена", reply_markup: reply_markup)
              end
              user.update(:step => nil)
            when 'update_field'
              bot.api.send_message(chat_id: message.chat.id, text: "Выберите запись для изменения")
              case message.text.to_i
              when 1
                users = User.all
                users_message = ""
                users.map do |user|
                  users_message += "#{user.id} - #{user.username}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: users_message)
                active_table = User 
              when 2
                passports = Passport.all
                passports_message = ""
                passports.map do |passport|
                  passports_message += "#{passport.id} - #{passport.nickname}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: passports_message)
                active_table = Passport        
              when 3
                kvests = Kvest.all
                kvests_message = ""
                kvests.map do |kvest|
                  kvests_message += "#{kvest.id} - #{kvest.kvest_name}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: kvests_message)
                active_table = Kvest    
              when 4
                titles = Title.all
                titles_message = ""
                titles.map do |title|
                  titles_message += "#{title.id} - #{title.title_name}\n"
                end
                bot.api.send_message(chat_id: message.chat.id, text: titles_message)
                active_table = Title
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Неверный ввод, повторите команду снова")
                user.update(:step => nil)
              end
              user.update(:step => 'choose_record')
            when 'choose_record'
              id = message.text
              record_message = ""
              record = active_table.find_by(:id => id)
              unless record.nil?
                record.attributes.each do |k, v| 
                  record_message += "#{k} - #{v}\n" unless k == "created_at" || k == "updated_at" || k == "id"
                  field_array.append(k)
                end
                bot.api.send_message(chat_id: message.chat.id, text: record_message)
                bot.api.send_message(chat_id: message.chat.id, text: "Выберите поле для изменения")
                user.update(:step => "choose_field")
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Неверный ввод, повторите команду снова")
                user.update(:step => nil)
              end
            when 'choose_field'
              field = message.text
              if field_array.include?(field)
                bot.api.send_message(chat_id: message.chat.id, text: "Введите новое значение для поля")
                user.update(:step => "update_field_value")
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Неверный ввод, повторите команду снова")
                user.update(:step => nil)
              end
            when 'update_field_value'
              value = message.text
              record.update(:"#{field}" => value)
              bot.api.send_message(chat_id: message.chat.id, text: "Запись обновлена")
              user.update(:step => nil)
            when 'input_pasport_title'
              passport_id = message.text
              titles = Title.all
              titles_message = ""
              titles.map do |title|
                titles_message += "#{title.id} - #{title.title_name}\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: titles_message)
              bot.api.send_message(chat_id: message.chat.id, text: "Выберите титул")
              user.update(:step => 'choose_title')
            when 'choose_title'
              title_id = message.text
              if Title.find_by(:id => title_id)
                unless Passport.find_by(:id => passport_id).titles.include? Title.find_by(:id => title_id)
                  Passport.find_by(:id => passport_id).titles << Title.find_by(:id => title_id)
                  bot.api.send_message(chat_id: message.chat.id, text: "Титул назначен")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Титул уже назначен пользователю")
                end
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Неверный ввод, повторите команду снова")
              end
              user.update(:step => nil)
            when "input_main_title"
              id = message.text
              unless Title.find_by(:id => id).nil?
                Passport.find_by(:id => user.passport_id).update(:main_title_id => id)
                bot.api.send_message(chat_id: message.chat.id, text: "Основной титул установлен")
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Неверный ввод, повторите команду снова")
              end
              user.update(:step => nil)
            when "input_substract"
              passports_number = message.text.split(" ")
              passports_number.map do |pass_number|
                passport = Passport.find_by(:id => pass_number)
                if passport
                  passport.update(:subscription => passport.subscription - 1)
                  if passport.subscription <= 3 && passport.subscription != 0
                    bot.api.send_message(chat_id: User.find_by(:passport_id => passport.id).telegram_id,
                     text: "У вас осталось #{passport.subscription} занятий в абонементе")
                  elsif passport.subscription == 0
                    bot.api.send_message(chat_id: 612352098,
                     text: "\xE2\x9A\xA0\xEF\xB8\x8F У #{passport.nickname} закончился абонемент \xE2\x9A\xA0\xEF\xB8\x8F")
                    bot.api.send_message(chat_id: User.find_by(:passport_id => passport.id).telegram_id,
                     text: "Ваш абонемент закончился \xF0\x9F\x98\xA2\nБегом за новым \xF0\x9F\x8F\x83")
                  end
                end
              end
              bot.api.send_message(chat_id: message.chat.id, text: "Занятия вычтены")
              user.update(:step => nil)
            when "input_bd"
              bd = message.text
              Passport.find_by(:id => user.passport_id).update(:bd => bd)
              user.update(:step => "input_mail")
              bot.api.send_message(chat_id: message.chat.id, text: "Введите адрес электронной почты:")
            when "input_mail"
              mail = message.text
              Passport.find_by(:id => user.passport_id).update(:mail => mail)
              user.update(:step => "input_number")
              bot.api.send_message(chat_id: message.chat.id, text: "Введите номер:")
            when "input_number"
              number = message.text
              Passport.find_by(:id => user.passport_id).update(:number => number)
              output_passport(user.passport_id, message, bot)
              user.update(:step => nil)
            when "input_player_passport_number"
              number = message.text
              unless Passport.find_by(:id => number).nil?
                output_passport(number, message, bot)
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Некорректный ввод, повторите команду")
              end
              user.update(:step => nil)
            when "input_abon_info"
              number = message.text
              reply_markup = user.admin ? admin_markup : remove_keyboard
              if number == "Отмена"
                bot.api.send_message(chat_id: message.chat.id, text: "Действие отменено", reply_markup: reply_markup)
                user.update(:step => nil)
              else
                passport = Passport.find_by(:id => number)
                unless passport.nil?
                  bot.api.send_message(chat_id: message.chat.id, text: "Имя: #{passport.nickname}\nДень рождения: #{passport.bd}\nНомер телефона: #{passport.number}\nОстаток абонемента: #{passport.subscription}\nДолг:#{passport.debt}", reply_markup: reply_markup)
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Некорректный ввод, повторите команду", reply_markup: reply_markup)
                end
              end
              user.update(:step => nil)
            when "input_change_info_field"
              info_number = message.text
              if info_number == "Отмена"
                reply_markup = user.admin ? admin_markup : remove_keyboard
                bot.api.send_message(chat_id: message.chat.id, text: "Действие отменено", reply_markup:reply_markup)
                user.update(:step => nil)
              else
                info_message = ""
                case info_number
                when "1"
                  update_field = "bd"
                  info_message = "даты рождения"
                when "2"
                  update_field = "mail"
                  info_message = "почты"
                when "3"
                  update_field = "number"
                  info_message = "номера мобильного телефона"
                end
                unless number in ["1", "2", "3"]
                  bot.api.send_message(chat_id: message.chat.id, text: "Введите новое значение для #{info_message}")
                  p update_field
                  user.update(:step => "input_info_value")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Некорректный ввод, повторите команду")
                  user.update(:step => nil)
                end
                
              end
            when "input_info_value"
              value = message.text
              Passport.find_by(:id => user.passport_id).update(update_field => value)
              reply_markup = user.admin ? admin_markup : remove_keyboard
              bot.api.send_message(chat_id: message.chat.id, text: "Значение обновлено", reply_markup: reply_markup)
              user.update(:step => nil)
            end
          end
      rescue
        bot.api.send_message(chat_id: message.chat.id, text: "Похоже возникла ошибка, проверьте правильность введенных данных и повторите ввод")
        user.update(:step => nil)
      end
    end
  end
end