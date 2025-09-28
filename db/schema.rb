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

ActiveRecord::Schema[8.0].define(version: 2025_09_23_153902) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "crypto_pairs", force: :cascade do |t|
    t.string "symbol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["symbol"], name: "index_crypto_pairs_on_symbol", unique: true
  end

  create_table "notification_channels", force: :cascade do |t|
    t.string "channel_type"
    t.jsonb "config"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_type"], name: "index_notification_channels_on_channel_type"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.string "channel_type"
    t.jsonb "message"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "price_thresholds", force: :cascade do |t|
    t.string "symbol", null: false
    t.decimal "value", precision: 20, scale: 10, null: false
    t.string "operator", null: false
    t.boolean "is_active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
