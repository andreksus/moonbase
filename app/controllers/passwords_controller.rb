class PasswordsController < Devise::PasswordsController
  prepend_before_action :require_no_authentication, except: :change_password

  def change_password
    if current_user and current_user.valid_password?(password_params[:current_password])
      if current_user.update_with_password(password_params)
        render json: {status: 200, notice: 'User password was updated successful'}
      else
        render json: {status: 401, notice: 'User password was not updated successful'}
      end
      bypass_sign_in current_user, scope: :user
    else
      render json: {status: 403, notice: 'User password incorrect'}
    end
  end

  # require "eth"

  def sign_up_by_wallet
    user = User.find_or_create_by(wallet_address: wallet_params[:wallet_address])
    unless user.nonce.present?
      user.nonce = SecureRandom.hex(24)
      user.save
      render json: {status: 200, nonce: user.nonce}
    else
      sign_in user
      render json: {status: 200, notice: "User already exists"}
    end
  end

  def check_signature

      user = User.find_by_wallet_address(sign_params[:wallet_address])
      message = "Message to sign: " + user.nonce
      signature = sign_params[:signature]
      user_address = user.wallet_address

      signature_pubkey = Eth::Key.personal_recover message, signature
      signature_address = Eth::Utils.public_key_to_address signature_pubkey

      if user_address.downcase.eql? signature_address.to_s.downcase
        sign_in user
        render json: {status: 200, notice: "User log in successful"}
      else
        render json: {status: 401, notice: "Signature failed"}
      end

  rescue Exception => e
    Rails.logger.info "User Auth by wallet failure: #{e.message}"
  end

  private
  def password_params
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end

  def wallet_params
    params.require(:user).permit(:wallet_address)
  end

  def sign_params
    params.require(:user).permit(:signature, :wallet_address)
  end
end
