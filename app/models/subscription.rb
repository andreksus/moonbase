class Subscription < ApplicationRecord
  attr_accessor :card_number, :exp_month, :exp_year, :cvc, :city, :country, :state, :postal_code, :line1, :holder
  # attr_accessor :period
  belongs_to :plan
  belongs_to :user
  validates :subscription_id, presence: true, uniqueness: true
  before_validation :create_stripe_reference, on: :create
  # before_validation :resume_subscription, on: :create
  # before_destroy :cancel_stripe_subscription
  # before_update :cancel_stripe_subscription, if: :subscription_inactive?

  def create_stripe_reference
    customer_id = user.create_or_update_stripe_reference({})
    # {
    #   city: city,
    #   country: country,
    #   state: state,
    #   postal_code: postal_code,
    #   line1: line1
    # }
    if Stripe::Customer.list_payment_methods(customer_id, {type: 'card'}).data.empty?
      Stripe::Customer.create_source(
        customer_id,
        { source: generate_card_token }
      )
      response = Stripe::Subscription.create({
                                               customer: customer_id,
                                               items: [
                                                 { price: plan.stripe_price_id }
                                               ]
                                             })
    else
      # plan = Plan.find(plan_id)
      response = Stripe::Subscription.create({
                                               customer: customer_id,
                                               items: [
                                                 { price: Plan.find(plan_id).stripe_price_id }
                                                 # { price: plan.stripe_price_id }
                                                 # { price: "price_1LE7IbGcmV04cK4JLl2RsxEv" }
                                               ]
                                             })
    end

    self.subscription_id = response.id
  end

  # def resume_subscription(period)
  #   price_id = Plan.find_by_interval_count(period).stripe_price_id
  #   customer_id = user.create_or_update_stripe_reference({})
  #   response = Stripe::Subscription.create({
  #                                            customer: customer_id,
  #                                            items: [
  #                                              { price: price_id }
  #                                            ]
  #                                          })
  #   self.subscription_id = response.id
  #
  # end

  def generate_card_token
    Stripe::Token.create({
                           card: {
                             number: card_number,
                             exp_month: exp_month,
                             exp_year: exp_year,
                             cvc: cvc,
                             name: holder,
                             address_line1: line1,
                             address_city: city,
                             address_state: state,
                             address_zip: postal_code,
                           }
                         }).id
  end

  def cancel
    Stripe::Subscription.delete(subscription_id)
    self.destroy
  end

  def subscription_inactive?
    !active
  end

end
