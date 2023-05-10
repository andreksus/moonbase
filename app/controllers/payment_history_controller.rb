class PaymentHistoryController < ApplicationController

  def create
    if @payment_history = PaymentHistory.create(payment_params)
      render json: { id: @payment_history.id, notice: 'Payment was created successful' }, status: :ok
    else
      render json: { status: :unprocessable_entity, notice: 'Payment was not created successful' }
    end
  end

  def update
    payment = current_user.payment_histories.find(params[:id])
    if payment.update(update_params)
      render json: { status: 200, notice: 'Payment was updated successful' }
    else
      render json: { status: :unprocessable_entity, notice: 'Payment was not updated successful' }
    end
  end

  def get_eth_price
    if price = Cryptocompare::Price.find('ETH', 'USD', { api_key: ENV['CRYPTOCOMPARE_KEY'] || '4da8748d1a152d54002d877881a044b896cf912b494273bd6e36b64263793701' })
      render json: {status: 200, price: price}
    else
      render json: {status: :unprocessable_entity, notice: 'Cannot get eth price'}
    end
  end

  def payment_params
    params.require(:payment).permit(:hex_value, :to, :from, :user_id, :status, :period)
  end

  def update_params
    params.require(:payment).permit(:user_id, :transaction_hash, :status)
  end

end
