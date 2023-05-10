class WalletController < ApplicationController
  before_action :set_wallet_tracker
  def index
    wallet = @wallet_tracker.get_normal_transactions_by_address(
      params_index[:address],
      params_index[:page],
      params_index[:offset],
      params_index[:sort]
    )
    render json: {info: wallet[:result]}
  end

  private
  def set_wallet_tracker
    @wallet_tracker = Etherscan.new()
  end

  def params_index
    params.permit(:page, :offset, :address, :sort)
  end
end
