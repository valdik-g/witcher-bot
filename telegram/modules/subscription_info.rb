# frozen_string_literal: true

# module for showing info about subscriptions for all users
module SubscriptionInfo
  def subscription_info(message, bot, user)
    if user.admin
      passports_message = Passport.where('subscription != 0').map do |passport|
        "#{passport.nickname}: #{passport.subscription}\n" if passport.subscription.to_i < 500
      end.join
      bot.api.send_message(chat_id: message.chat.id, text: passports_message)
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end
end
