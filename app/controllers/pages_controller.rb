class PagesController < ActionController::Base

  def join
    render 'join/join'
  end

  def plan
    render 'plan/plan'
  end

  def class_page
    render 'class/class'
  end

  def order_confirmation
    render 'order_confirmation/order_confirmation'
  end

  def order_confirmation_payment
    render 'order_confirmation_payment/order_confirmation_payment'
  end

  def training
    render 'training/training'
  end

  def members
    render 'members/members'
    end

  def members_confirmation
    render 'members_confirmation/members_confirmation'
  end

end