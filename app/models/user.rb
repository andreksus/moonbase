class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :confirmable
  has_many :payment_histories, :dependent => :destroy
  has_many :saved_collections, :dependent => :destroy
  has_many :tracked_wallet_addresses, :dependent => :destroy
  has_many :owned_assets, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy
  has_one_attached :photo
  validates_uniqueness_of :email, :allow_blank => true, :allow_nil => true, if: :wallet_address?
  validates :customer_id, presence: true, uniqueness: true, allow_blank: true
  before_validation :create_stripe_reference, on: :create
  after_update :download_owned_assets, :publish_user_info_to_redis
  after_create :download_owned_assets
  before_create :generate_channel_key
  # validates :email, :password, :presence => true, :unless => :UserController.check_wallet

  def after_database_authentication
    begin
      publish_user_info_to_redis
    rescue;end
  end

  def generate_channel_key
    begin
      key = SecureRandom.urlsafe_base64
    end while User.where(:channel_key => key).exists?
    self.channel_key = key
  end

  def publish_user_info_to_redis
    begin
    $redis.publish(
      "#{self.channel_key}_user_info",
      {
        user: self.slice(
          :owned_assets_is_updating_time,
          :owned_assets_is_updating,
          :wallet_address,
          :email,
          :phone_number,
          :avatar,
          :channel_key
        ).merge({have_owned_assets_in_db: self.owned_assets.count > 0}),
        payment: self.get_payment_information,
        eth_price:  Cryptocompare::Price.find(['KLAY', 'MATIC', 'ETH'], ['USD', 'MATIC', 'ETH', 'KLAY'], { api_key: ENV['CRYPTOCOMPARE_KEY'] || '4da8748d1a152d54002d877881a044b896cf912b494273bd6e36b64263793701' })
      }.to_json)
    rescue ;end
  end



  def download_owned_assets

    if wallet_address_changed? || saved_change_to_wallet_address?
      self.owned_assets.destroy_all unless previous_changes[:wallet_address][1].present?
      if previous_changes[:wallet_address][0] != previous_changes[:wallet_address][1] && previous_changes[:wallet_address][1].present?
        self.owned_assets.destroy_all
        if Rails.env.production?
          if self.wallet_address.present?
            DownloadOwnedAssetsJob.perform_later(self.id)
            PullingEventsByType.perform_later(DateTime.now.utc.to_i, 'successful', self.id)
            PullingEventsByType.perform_later(DateTime.now.utc.to_i, 'transfer', self.id)
          end
        else
          # DownloadOwnedAssetsJob.perform_now(self.id) if self.wallet_address.present?
        end
      end
    end
  end

  def fred_premium
    %w[fred@iprogroup.ca info@jiamtam.com julianxyzhao@gmail.com chris.lebert@live.ca picard@nftrockstars.io keric_wu@hotmail.ca michael@nftrockstars.io warren+premium@iprogroup.ca].include?(self.email)
  end

  def fred_premium_1y
    %w[teoroyston@gmail.com coachcarole123@gmail.com].include?(self.email)
  end

  def get_payment_information
    if payment = self.payment_histories.where(user_id: self.id ).where("updated_at <= created_at + interval '30' day").where(status: 1).where(period: 1).last
      if (payment.updated_at + 30.days >= Time.now && payment.status == 1)
        subscription = true
        days_left = (payment.updated_at + 30.days - Time.now).to_i / 86400
      else
        subscription = false
      end
      return {:status => payment.status, :subscription => subscription, :subscription_expires =>  payment.updated_at + (payment.period == 1 ? 1.month : 6.months), :days_left => days_left, :payment_source => "metamask", :period => payment.period}
    # else

      elsif payment = self.payment_histories.where(user_id: self.id ).where("updated_at <= created_at + interval '180' day").where(status: 1).where(period: 2).last
        if (payment.updated_at + 180.days >= Time.now && payment.status == 1)
          subscription = true
          days_left = (payment.updated_at + 180.days - Time.now).to_i / 86400
        else
          subscription = false
        end
        return {:status => payment.status, :subscription => subscription, :subscription_expires =>  payment.updated_at + (payment.period == 1 ? 1.month : 6.months), :days_left => days_left, :payment_source => "metamask", :period => payment.period}
      else

      if payment = self.subscriptions.where(active: true).last
        return {:status => payment.active, :subscription => true, :subscription_expires => payment.updated_at + (payment.plan_id == 1 ? 1.month : 6.months), :days_left => (payment.updated_at + (payment.plan_id == 1 ? 30.days : 6.months) - Time.now).to_i / 86400 , :plan_id => payment.plan_id, :subscription_id => self.subscriptions.last.id, :payment_source => "stripe"}
      elsif fred_premium
        return {:status => "active", :subscription => true, :subscription_expires => DateTime.now + 99.years, :days_left => 9999.days}
      elsif fred_premium_1y && (1664517546 + 1.year.to_i > Time.now.utc.to_i)
        return {:status => "active", :subscription => true, :subscription_expires => (Time.at(1664517546) + 1.year).to_datetime, :days_left => ((Time.at(1664517546) + 1.year) - Time.now).to_i / 86400}
      else
        return {}
      end
    end
  end

  def create_stripe_reference
    response = Stripe::Customer.create(email: email, address: address)
    self.customer_id = response.id
  end

  def create_or_update_stripe_reference(address = {})
    unless self.customer_id.present?
      response = if self.email.present?
                    Stripe::Customer.create(email: email)
                 else
                    Stripe::Customer.create()
                 end
      self.update({customer_id: response.id})
    end
    self.customer_id
  end

  def add_payment_method(card, address)
    self.create_or_update_stripe_reference({})

    response = Stripe::Customer.create_source(
      self.customer_id,
      { source: generate_card_token(card, address) }
    )

    true if response.present?
  rescue StandardError => e
    e.message
  end

  def generate_card_token(card, address)
    Stripe::Token.create({
                           card: card_object(card, address)
                         }).id
  end

  def retrieve_stripe_reference
    Stripe::Customer.retrieve(self.customer_id)
  end

  def retrieve_stripe_payment_methods
    self.create_or_update_stripe_reference(address({}))
    Stripe::Customer.list_payment_methods(
      self.customer_id,
      { type: 'card', }
    )
    end

  def retrieve_stripe_single_payment_method(id)
    Stripe::Customer.retrieve_source(
      self.customer_id,
      id,
      )
  end

  def set_default_payment(payment_id)
    Stripe::Customer.update(self.customer_id, {default_source: payment_id})
  end

  def delete_payment_method(id)
    Stripe::Customer.delete_source(
      self.customer_id,
      id,
      )
    end

  def update_payment_method(card, address, card_id)
    Stripe::Customer.update_source(
      self.customer_id,
      card_id,
      card_object(card, address)
      )
  end

  def address(object = nil)
    {
      city: object[:city],
      state: object[:state],
      postal_code: object[:postal_code],
      line1: object[:line1],
      country: object[:country]
    } if object.present?
  end

  def card_object(card, address)
    {
      number: card[:card_number],
      exp_month: card[:exp_month],
      exp_year: card[:exp_year],
      cvc: card[:cvc],
      name: card[:holder],
      address_line1: address[:line1],
      address_city: address[:city],
      address_state: address[:state],
      address_zip: address[:postal_code],
      address_country: address[:country],
    }.compact
  end


  def invoices
    customer_id =  self.customer_id
    Stripe::Invoice.search(query: "customer:\"#{customer_id}\"")
  end
end
