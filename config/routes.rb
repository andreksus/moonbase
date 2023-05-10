Rails.application.routes.draw do
  get 'payment_history/index'
  get 'fee/index'
  get 'wallet/index'
  # post '/users/wallet' => 'api/v1/user#check_wallet'
  get '/join' => 'pages#join'
  get '/plan' => 'pages#plan'
  get '/class' => 'pages#class_page'
  get '/order-confirmation' => 'pages#order_confirmation'
  get '/order-confirmation-payment' => 'pages#order_confirmation_payment'
  get '/training' => 'pages#training'
  get '/member' => 'pages#members'
  get '/members-confirmation' => 'pages#members_confirmation'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_for :users, controllers: { confirmations: 'confirmations', sessions: 'sessions' }, skip: [:password]
  devise_scope :user do
    get '/users/password/new' => 'devise/passwords#new', :as => 'new_user_password'
    get '/users/password/edit' => 'home#index', :as => 'edit_user_password'
    # patch '/users/password' => 'devise/passwords#update'
    patch '/users/password/change' => 'passwords#change_password'
    post '/users/wallet/sign_up' => 'passwords#sign_up_by_wallet'
    post '/users/wallet/check_signature' => 'passwords#check_signature'
    put '/users/password' => 'devise/passwords#update'
    post '/users/password' => 'devise/passwords#create', :as => 'user_password'
  end

  namespace :api do
    namespace :v1 do

      post 'payment/' => 'crypto_payment#create'
      put 'payment/:payment_id' => 'crypto_payment#update'

      get 'collections/:id' => 'event#single_collection', as: 'single_collection'
      get 'collections_stats/:id' => 'event#collection_stats'
      get 'collection_listings/:id' => 'event#collection_listings'
      get 'listings_list/:id' => 'event#listings_list'
      post 'collection_listings/update' => 'open_api#update_listings'
      post 'item_sales/update' => 'open_api#update_item_sales'
      get 'sales_list/:id' => 'event#sales_list'
      get 'sales_graph/:id' => 'event#sales_graph'

      get 'trending_collections' => 'event#trending_collections_by_time'
      get 'trending_collections_1m' => 'item_sale#trending_collections_by_time'

      get 'saved_collection_1m' => ''

      get 'top_10_holders/:collection_id' => 'event#top_10_holders'

      get 'trending/assets' => 'trending#get_assets'
      get 'trending/asset/:asset_contract_address/:token_id' => 'trending#get_single_asset'
      get 'trending/collection/:collection_slug' => 'trending#get_single_collection'

      resources :trending
      resources :user
      resources :saved_collection
      resources :tracked_wallet_addresses
      resources :subscriptions, only: %i[show create update]



      delete 'subscriptions/cancel/:id' => 'subscriptions#destroy'
      post 'subscriptions/resume' => 'subscriptions#resume'

      post 'users/payment/add' => 'stripe#create_payment_method'
      get 'users/payment/all' => 'stripe#retrieving_payment_methods'
      get 'users/payment/:id' => 'stripe#retrieving_single_payment_method'
      delete 'users/payment/delete/:id' => 'stripe#delete_payment_method'
      patch 'users/payment/update/:id' => 'stripe#update_payment_methods'
      post 'users/payment/default/set/:id' => 'stripe#set_default'
      get 'users/payment/invoice/get' => 'stripe#retrieving_invoices'

      post 'stripe/webhooks' => "stripe_webhooks#webhooks"

      post 'photo/update' =>  'photos#update'
      delete 'photo/delete' => 'photos#delete'
      get 'events' => 'event#trending_collection_by_time'
      get 'top_transactions' => 'tracked_wallet_addresses#get_top_transactions'

      get 'trending_collections' => 'event#trending_collections_by_time'
      get 'trending_collections/:id' => 'event#single_collection_by_time'
      get 'trending_collections/opensea/stats/:id' => 'trending#trending_collections_by_time_basic_analytic'
      get 'trending_collections/activity/:collection_id' => 'event#collection_activity_tab'



      get 'portfolio/gallery' => 'portfolio#get_info_for_gallery'
      get 'portfolio/analyser/' => 'portfolio#get_info_for_analyser'
      get 'portfolio/global/' => 'portfolio#index'
      get 'portfolio/global/graph' => 'portfolio#get_data_for_graph'
      get 'portfolio/asset/' => 'portfolio#get_info_individual_nft'


      get 'search/global' => 'search#search_by_query'
      get 'search/account' => 'search#search_by_account'
      get 'users/get_by_wallet/:wallet_address' => 'user#does_wallet_user_exist'

    end
  end

  # put 'payment/create' => 'payment_history#create', as: 'send_transaction'
  # put 'api/v1/payment/create' => 'payment_history#create'
  # put 'api/v1/payment/update/:id' => 'payment_history#update', as: 'update_transaction'
  get 'api/v1/payment/price' => 'payment_history#get_eth_price'



  post 'task/perform'
  post 'task/pulling_events_by_type_successful'
  post 'task/pulling_events_by_type_transfer'
  post 'task/pulling_events_by_type_created'
  post 'task/pulling_events_by_type_cancelled'
  post 'task/delete_listings_which_expiration'
  post 'task/check_updating_users'
  post 'task/get_gas_fee'
  post 'task/health_check_workers'



  root to: 'home#index'
  get '*path', to: 'home#index', constraints: lambda { |req|
  req.path.exclude? 'rails/active_storage'
  }
  get '/success_sign_in', to: 'application#success_sign_in'
  post '/success_sign_in', to: 'application#success_sign_in'
end