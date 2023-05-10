class Plan < ApplicationRecord
  validates :name,
            :stripe_price_id,
            :price_cents, presence: true
  validates :name,
            :stripe_price_id, uniqueness: true
  enum interval: %i[month year]
  before_validation :create_stripe_reference, on: :create

  def create_stripe_reference
    response = Stripe::Price.create({
                                      unit_amount: price_cents,
                                      currency: 'usd',
                                      recurring: { interval: interval, interval_count: interval_count },
                                      product_data: { name: name }
                                    })
    self.stripe_price_id = response.id
  end

  def retrieve_stripe_reference
    Stripe::Price.retrieve(stripe_price_id)
  end
end
