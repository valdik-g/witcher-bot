# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_08_07_152057) do
  create_table "buffs", force: :cascade do |t|
    t.string "buff_name", default: ""
    t.string "buff_description", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "buffs_passports", force: :cascade do |t|
    t.integer "buff_id"
    t.integer "passport_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kvests", force: :cascade do |t|
    t.string "kvest_name"
    t.integer "crons_reward"
    t.string "additional_reward"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level_reward"
    t.integer "title_id"
    t.integer "additional_kvest", default: 0
    t.integer "kvest_repeat", default: 0
  end

  create_table "kvests_passports", force: :cascade do |t|
    t.integer "kvest_id"
    t.integer "passport_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "passports", force: :cascade do |t|
    t.string "nickname"
    t.integer "crons"
    t.string "description"
    t.string "school"
    t.string "level"
    t.string "rank"
    t.integer "additional_kvest", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "telegram_nick"
    t.integer "long_kvest_id"
    t.string "history", default: ""
    t.string "elixirs"
    t.string "inventory", default: ""
    t.integer "main_title_id"
    t.integer "subscription", default: 0
    t.integer "debt", default: 0
    t.string "bd", default: ""
    t.string "mail", default: ""
    t.string "number", default: ""
    t.string "familiar", default: "Фамальяр еще не получен"
    t.integer "kvest_repeat", default: 0
  end

  create_table "passports_titles", force: :cascade do |t|
    t.integer "title_id"
    t.integer "passport_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prerecordings", force: :cascade do |t|
    t.boolean "closed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "choosed_options", default: ""
    t.string "closed_prerecordings", default: ""
    t.string "available_trainings", default: ""
  end

  create_table "products", force: :cascade do |t|
    t.string "item"
    t.integer "cost"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "titles", force: :cascade do |t|
    t.string "title_name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tournaments", force: :cascade do |t|
    t.integer "crons"
    t.integer "additional_kvest"
    t.integer "repeat_kvest"
    t.string "pairs"
    t.string "winners"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "additional_reward"
  end

  create_table "user_prerecordings", force: :cascade do |t|
    t.integer "passport_id"
    t.string "days", default: ""
    t.integer "message_id"
    t.boolean "voted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.integer "telegram_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.string "step"
    t.integer "passport_id"
  end

end
