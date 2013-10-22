# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131022001305) do

  create_table "squarrel_authentications", force: true do |t|
    t.string   "nut",        null: false
    t.string   "orig_ip",    null: false
    t.string   "ip",         null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "squarrel_authentications", ["nut"], name: "index_squarrel_authentications_on_nut", unique: true

  create_table "squarrel_users", force: true do |t|
    t.string   "pub_key",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "squarrel_users", ["pub_key"], name: "index_squarrel_users_on_pub_key", unique: true

end
