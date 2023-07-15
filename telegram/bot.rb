# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'json'

export = %w[AccrueVisitings AssignTitle BotHelper ChangeRecord ClosePrerecording CompleteKvest CreateKvest 
            CreatePassports CreateTitle CreateTournament Notification OpenPrerecording PlayerInfo RankUp 
            SubscriptionInfo SubstractCrons SubstractVisitings AddItemToInventory]
export_for_user = %w[Birthdays ChangeDescription ChangeInfo ChooseTitle GetBest GetHistory GetInventory GetKvests 
                      GetPassport GetPlayer GetSubscription LeaveFeedback Meme TransferCrons UpdateHistory]

options =  ["Пт\xE2\x9A\x94", "Сб1\xE2\x9A\x94", "Сб2\xE2\x9A\x94", "Сб2\xf0\x9f\x8f\xb9",
            "Сб3\xf0\x9f\x8f\xb9" "Вс0\xE2\x9A\x94", "Вс1\xE2\x9A\x94", "Вс2\xE2\x9A\x94", "Вс3\xf0\x9f\x8f\xb9"]

['./telegram/modules/*.rb', './telegram/modules/user_modules/*.rb'].each { |p| Dir[p].each { |f| require f } }
export.each { |m| include(Kernel.const_get(m)) }
export_for_user.each { |m| include(Kernel.const_get(m)) }

token = '5587814730:AAFci39iNXTgIeDLVTvKpCjULW2a94zbuP8'

Telegram::Bot::Client.run(token) do |bot|
  Sidekiq::Cron::Job.create(
    name: 'BirthdayCheck',
    cron: '00 12 * * * Europe/Minsk',
    class: 'BirthdayCheckWorker'
  )

  bot.listen do |message|
    # message = nil
    case message
    when Telegram::Bot::Types::PollAnswer
      user = User.find_by(telegram_id: message.user.id)
      if user.step == 'create_prerecording'
        create_prerecording(message, bot, user, @vote_message)
      elsif Prerecording.last.closed
        bot.api.send_message(chat_id: message.user.id, text: 'Предзапись уже закрыта, ждите дальнейших новостей')
      else
        prerecord_user(bot, message, user)
      end
    when Telegram::Bot::Types::CallbackQuery
      case message.data
      when 'inventory' then get_inventory(message, bot)
      when 'passport'  then get_passport_back(message, bot)
      end
    when Telegram::Bot::Types::Message
      begin
        user = find_or_build_user(message.from)
        # if [822_281_212, 6185223601].include?(user.telegram_id) # , 612_352_098, 499620114, 940051147
        unless message.text.nil? && !message.text.empty? # && message.document.nil?
          return_buttons(user, bot, message.chat.id, 'Действие отменено') if message.text == 'Отмена'
          case user.step
          when nil
            case message.text
            when '/start'
              bot.api.send_message(chat_id: message.chat.id,
                                  text: "Привет, я бот клуба 'Свое Дело'!\nСписок моих команд находится внизу, "\
                                        "удачи \xE2\x9D\xA4")
            when '/passport'
              get_passport(message, bot, user)
            when '/get_best'
              get_best(message, bot, user)
            when '/get_history'
              get_history(message, bot, user)
            when '/update_history'
              update_history(message, bot, user)
            when '/get_kvests'
              get_kvests(message, bot, user)
            when '/change_info'
              change_info(message, bot, user)
            when '/birthdays'
              birthdays(message.chat.id, bot)
            when '/feedback'
              leave_feedback(message, bot, user)
            when '/choose_title'
              choose_title(message.chat.id, bot, user)
            when '/get_player'
              get_player(message, bot, user)
            when '/mem'
              meme(message, bot, user)
            when '/subscription'
              get_subscription(message, bot, user)
            when '/transfer_crons'
              transfer_crons(message, bot, user)
            when '/prerecording'
              bot.api.send_message(chat_id: message.chat.id, text: Prerecording.last.close_message)
            when '/shop'
              bot.api.send_message(chat_id: message.chat.id, text:'Работаем над этим')
              # output_shop(message, bot, user)
            when 'Создать паспорт'
              create_passport(message, bot, user)
            when 'Изменить запись'
              change_record(message, bot, user)
            when 'Создать квест'
              create_kvest(message, bot, user)
            when 'Выполнить квест'
              complete_kvest(message, bot, user)
              @repeat = false
            when 'Повторить квест'
              complete_kvest(message, bot, user)
              @repeat = true
            when 'Создать титул'
              create_title(message, bot, user)
            when 'Назначить титул'
              assign_title(message, bot, user)
            when 'Списать занятия'
              substract_visitings(message, bot, user)
            when 'Информация по игроку'
              player_info(message, bot, user)
            when 'Информация по всем абонементам'
              subscription_info(message, bot, user)
            when 'Провести турнир'
              create_tournamet(message, bot, user)
            when 'Открыть предзапись'
              open_prerecording(message, bot, user)
            when 'Закрыть предзапись'
              close_prerecording(message, bot, user)
            when 'Списать кроны'
              substract_crons(message, bot, user)
            when 'Начислить занятия'
              accrue_visitings(message, bot, user)
            when 'Повысить ранг'
              rank_up(message, bot, user)
            when 'Уведомление'
              notification(message, bot, user)
            when '/remove'
              return_buttons(user, bot, message.chat.id, 'Кнопки убраны')
            when 'Изменить описание'
              change_description(message, bot, user)
            when 'Добавить предмет'
              choose_players_inventory(message, bot, user)
            end
          # Passport creation
          when 'input_name'
            @witcher_name = input_name(message, bot, user)
          when 'input_school'
            @passport = input_school(message, bot, user, @witcher_name)
          when 'input_telegram_nick'
            input_telegram_nick(message, bot, user, @passport)
          when 'change_user_description'
            description = message.text
            user.passport.update(description: description)
            return_buttons(user, bot, message.chat.id, 'Описание успешно обновлено')
          # Kvest creation
          when 'input_kvest_name'
            @kvest_name = input_kvest_name(message, bot, user)
          when 'input_crons_reward'
            @crons_reward = input_crons_reward(message, bot, user)
          when 'input_level_reward'
            @level_reward = input_level_reward(message, bot, user)
          when 'input_title_reward'
            @title_reward = input_title_reward(message, bot, user, @kvest_name)
          when 'input_addkvest_reward'
            @addkvest_reward = input_addkvest_reward(message, bot, user)
          when 'input_repeat_kvest_reward'
            @repeat_revard = input_repeat_kvest_reward(message, bot, user)
          when 'input_additional_reward'
            input_additional_reward(message, bot, user, {:kvest_name => @kvest_name, :crons_reward => @crons_reward,
                                                         :level_reward => @level_reward, :title_reward => @title_reward,
                                                         :addkvest => @addkvest_reward, 
                                                         :repeat => @repeat_revard})
          when 'input_passport_number'
            @passport_number = input_passport_number(message, bot, user)
          when 'input_kvest_number'
            input_kvest_number(message, bot, user, @passport_number, @repeat)
          when 'input_title_name'
            @title_name = input_title_name(message, bot, user)
          when 'input_title_description'
            input_title_description(message, bot, user, @title_name)
          when 'change_history'
            change_history(message, bot, user)
          when 'choose_table'
            @active_table = choose_table(message, bot, user)
          when 'choose_record'
            @record = choose_record(message, bot, user, @active_table)
          when 'choose_field'
            @field = choose_field(message, bot, user, @record)
          when 'update_field_value'
            update_field_value(message, bot, user, @record, @field)
          when 'input_pasport_title'
            @passport_id = input_pasport_title(message, bot, user)
          when 'choose_title'
            choose_title_to_assign(message, bot, user, @passport_id)
          when 'input_main_title'
            input_main_title(message, bot, user)
          when 'input_substract'
            input_substract(message, bot, user)
          when 'input_bd'
            @bd = input_bd(message, bot, user)
          when 'input_mail'
            @mail = input_mail(message, bot, user)
          when 'input_number'
            input_number(message, bot, user, @bd, @mail)
          when 'input_player_passport_number'
            input_player_passport_number(message, bot, user)
          when 'input_abon_info'
            input_abon_info(message, bot, user)
          when 'input_change_info_field'
            @update_field = input_change_info_field(message, bot, user)
          when 'input_info_value'
            input_info_value(message, bot, user, @update_field)
          when 'input_vote_message'
            @vote_message = input_vote_message(message, bot, user)
          when 'input_descr_passport'
            @change_passport_h = input_descr_passport(message, bot, user)
          when 'input_new_description'
            input_new_description(message, bot, user, @change_passport_h)
          when 'choose_user_visibility'
            @send_feedbacks_author = choose_user_visibility(message, bot, user)
          when 'enter_feedback'
            enter_feedback(message, bot, user, @send_feedbacks_author)
          when 'input_passport_to_substract'
            @passport_id = input_passport_to_substract(message, bot, user)
          when 'input_crons_to_substract'
            input_crons_to_substract(message, bot, user, @passport_id)
          when 'input_subscription_addition'
            @passport_id = input_subscription_addition(message, bot, user)
          when 'add_subscription'
            add_subscription(message, bot, user, @passport_id)
          when 'input_passport_rank'
            input_passport_rank(message, bot, user)
          when 'input_notification'
            input_notification(message, bot, user)
          when 'input_tournament_crons'
            input_tournament_crons(message, bot, user)
          when 'input_tournament_additional_kvest'
            input_tournament_additional_kvest(message, bot, user)
          when 'input_tournament_repeat_kvest'
            input_tournament_repeat_kvest(message, bot, user)
          when 'input_tournament_additional_reward'
            input_tournament_additional_reward(message, bot, user)
          when 'create_tournament_grid'
            create_tournament_grid(message, bot, user, message.text.split(' '))
          when 'choose_winner'
            choose_winner(message, bot, user)
          when 'input_passport_to_transfer'
            @passport_id = input_passport_to_transfer(message, bot, user)
          when 'transfer_crons'
            user.passport.transfer_crons(message.text.to_i, @passport_id, message.chat.id, bot, user)
          when 'choose_item_to_add'
            @players = choose_item_to_add(message, bot, user)
          when 'add_item_to_inventory'
            add_item_to_inventory(message, bot, user, @players)
          end
        end
        # else
        #   bot.api.send_message(chat_id: message.chat.id, text: "Ведутся работы, пожалуйста подождите")
        # end
      rescue StandardError
        return_buttons(user, bot, message.chat.id,
                       'Похоже возникла ошибка, проверьте правильность введенных данных и повторите ввод')
      end
    end
  end
end
