# frozen_string_literal: true

# module for getting all bp levels for all players
module GetAllPlayersBP
  def get_all_players_bp(message, bot, user)
    if user.admin
      levels = Passport.where("bp_level > 0").select(:nickname, :bp_level)
      levels_message = levels.map { |p| "#{p.nickname}: #{p.bp_level} lvl"}.join("\n")
      bot.api.send_message(chat_id: message.chat.id,
                            text: "Уровни боевого пропуска:\n#{levels_message}")
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Ты как сюда залез?)')
    end
  end
end
  