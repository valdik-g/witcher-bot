# frozen_string_literal: true

# module for getting memes
module Meme
  def meme(message, bot, _user)
    meme = (Dir.entries('/home/cloud-user/witcher-bot/witcher-bot/telegram/memes').reject do |f|
              File.directory? f
            end).sample
    bot.api.sendPhoto(chat_id: message.chat.id,
                      photo: Faraday::UploadIO.new(
                        "/home/cloud-user/witcher-bot/witcher-bot/telegram//memes/#{meme}", 'image/jpg'
                      ))
  end
end
