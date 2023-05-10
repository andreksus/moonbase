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

ActiveRecord::Schema.define(version: 2022_09_29_114020) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "timescaledb"

  create_table "accounts", force: :cascade do |t|
    t.text "address", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "name"
    t.string "profile_img_url", default: ""
    t.index ["address"], name: "index_accounts_on_address", unique: true
    t.index ["name"], name: "index_accounts_on_name"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assets", force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.text "url"
    t.text "image_url"
    t.datetime "contract_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "collection_id", null: false
    t.text "contract_address", null: false
    t.text "token_id", null: false
    t.string "animation_url"
    t.index ["collection_id"], name: "index_assets_on_collection_id"
    t.index ["contract_address"], name: "index_assets_on_contract_address"
    t.index ["token_id"], name: "index_assets_on_token_id"
  end

  create_table "collections", force: :cascade do |t|
    t.text "slug"
    t.text "name"
    t.text "image_url"
    t.text "large_image_url"
    t.text "discord_url"
    t.text "telegram_url"
    t.text "twitter_username"
    t.text "instagram_username"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "description"
    t.text "payout_address"
    t.text "external_url"
    t.text "contract_address"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
  end

  create_table "event_transfers", id: false, force: :cascade do |t|
    t.bigint "id", null: false
    t.datetime "created_date", null: false
    t.integer "quantity"
    t.float "total_price"
    t.bigint "asset_id", null: false
    t.bigint "collection_id", null: false
    t.bigint "seller_account_id"
    t.bigint "from_account_id"
    t.bigint "to_account_id"
    t.bigint "winner_account_id"
    t.string "transaction_hash"
    t.string "transaction_index"
    t.string "block_hash"
    t.string "block_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["asset_id"], name: "index_event_transfers_on_asset_id"
    t.index ["collection_id"], name: "index_event_transfers_on_collection_id"
    t.index ["created_date"], name: "index_event_transfers_on_created_date"
    t.index ["id", "created_date"], name: "index_event_transfers_on_id_and_created_date", unique: true
    t.index ["winner_account_id"], name: "index_event_transfers_on_winner_account_id"
  end

  create_table "events", id: false, force: :cascade do |t|
    t.bigint "id", null: false
    t.datetime "created_date", null: false
    t.integer "quantity", null: false
    t.float "total_price", null: false
    t.bigint "asset_id", null: false
    t.bigint "collection_id", null: false
    t.bigint "seller_account_id", null: false
    t.bigint "from_account_id", null: false
    t.bigint "to_account_id", null: false
    t.bigint "winner_account_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "payment_symbol", null: false
    t.string "transaction_hash"
    t.string "transaction_index"
    t.string "block_hash"
    t.string "block_number"
    t.index ["asset_id"], name: "index_events_on_asset_id"
    t.index ["collection_id"], name: "index_events_on_collection_id"
    t.index ["created_date"], name: "index_events_on_created_date"
    t.index ["id", "created_date"], name: "index_events_on_id_and_created_date", unique: true
    t.index ["payment_symbol"], name: "index_events_on_payment_symbol"
    t.index ["seller_account_id"], name: "index_events_on_seller_account_id"
    t.index ["winner_account_id"], name: "index_events_on_winner_account_id"
  end

  create_table "item_sales", force: :cascade do |t|
    t.float "sale_price"
    t.bigint "quantity"
    t.text "payment_token"
    t.datetime "created_date", null: false
    t.string "order_hash"
    t.bigint "maker_id"
    t.bigint "taker_id"
    t.text "img_url"
    t.text "token_id"
    t.bigint "asset_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "contract_address"
    t.bigint "collection_id"
    t.index ["asset_id"], name: "index_item_sales_on_asset_id"
  end

  create_table "listings", force: :cascade do |t|
    t.float "base_price"
    t.bigint "quantity"
    t.text "payment_token"
    t.datetime "created_date", null: false
    t.datetime "listing_time"
    t.datetime "expiration_time"
    t.bigint "maker_id"
    t.bigint "taker_id"
    t.bigint "asset_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "order_hash", default: "", null: false
    t.text "img_url"
    t.text "token_id"
    t.index ["asset_id"], name: "index_listings_on_asset_id"
    t.index ["created_date"], name: "index_listings_on_created_date"
    t.index ["order_hash"], name: "index_listings_on_order_hash", unique: true
  end

  create_table "owned_assets", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "asset_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "date_of_sale"
    t.datetime "purchase_date"
    t.float "purchase_price_eth"
    t.index ["asset_id"], name: "index_owned_assets_on_asset_id"
    t.index ["user_id"], name: "index_owned_assets_on_user_id"
  end

  create_table "payment_histories", force: :cascade do |t|
    t.string "transaction_hash"
    t.string "gas_price"
    t.string "hex_value"
    t.string "from"
    t.string "to"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.integer "period"
    t.datetime "created_date"
    t.datetime "updated_date"
    t.string "contract_address"
    t.index ["user_id"], name: "index_payment_histories_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "interval"
    t.integer "price_cents"
    t.string "stripe_price_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "interval_count", default: 1
  end

  create_table "saved_collections", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.bigint "collection_id", null: false
    t.index ["collection_id"], name: "index_saved_collections_on_collection_id"
    t.index ["user_id", "collection_id"], name: "index_saved_collections_on_user_id_and_collection_id", unique: true
    t.index ["user_id"], name: "index_saved_collections_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "user_id", null: false
    t.boolean "active", default: true
    t.string "subscription_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "temp_event_listings", id: false, force: :cascade do |t|
    t.bigint "id", null: false
    t.datetime "created_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["id", "created_date"], name: "index_temp_event_listings_on_id_and_created_date", unique: true
  end

  create_table "tracked_wallet_addresses", force: :cascade do |t|
    t.string "user_name"
    t.string "address"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_tracked_wallet_addresses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "wallet_address"
    t.string "phone_number"
    t.boolean "sms_alert", default: false
    t.string "avatar"
    t.string "nonce"
    t.string "customer_id"
    t.boolean "owned_assets_is_updating", default: false
    t.datetime "owned_assets_is_updating_time"
    t.string "channel_key", default: ""
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assets", "collections", on_delete: :cascade
  add_foreign_key "event_transfers", "accounts", column: "from_account_id", on_delete: :cascade
  add_foreign_key "event_transfers", "accounts", column: "seller_account_id", on_delete: :cascade
  add_foreign_key "event_transfers", "accounts", column: "to_account_id", on_delete: :cascade
  add_foreign_key "event_transfers", "accounts", column: "winner_account_id", on_delete: :cascade
  add_foreign_key "event_transfers", "assets", on_delete: :cascade
  add_foreign_key "event_transfers", "collections", on_delete: :cascade
  add_foreign_key "events", "accounts", column: "from_account_id", on_delete: :cascade
  add_foreign_key "events", "accounts", column: "seller_account_id", on_delete: :cascade
  add_foreign_key "events", "accounts", column: "to_account_id", on_delete: :cascade
  add_foreign_key "events", "accounts", column: "winner_account_id", on_delete: :cascade
  add_foreign_key "events", "assets", on_delete: :cascade
  add_foreign_key "events", "collections", on_delete: :cascade
  add_foreign_key "item_sales", "assets"
  add_foreign_key "listings", "assets"
  add_foreign_key "owned_assets", "assets"
  add_foreign_key "owned_assets", "users"
  add_foreign_key "payment_histories", "users"
  add_foreign_key "saved_collections", "collections"
  add_foreign_key "saved_collections", "users"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tracked_wallet_addresses", "users"
end
