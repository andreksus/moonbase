class FeeController < ApplicationController
    before_action :set_gas_fee
    def index
      fee = @gas_fee.response
      @gas_fee.redis_submit(fee)
      render json: {info: fee}
    end

    private
    def set_gas_fee
      @gas_fee = GasFee.new()
    end
  end

