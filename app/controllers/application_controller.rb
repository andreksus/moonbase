class ApplicationController < ActionController::Base
  respond_to :html, :json
  after_action :set_access_control_headers
  # def after_sign_in_path_for(resource)
  #   respond_to :json
  # end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def success_sign_in(resource)
    return {status:"ok"}
  end


end
