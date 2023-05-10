class SessionsController < Devise::SessionsController
  def new
    super
  end

  def create
    if user = User.find_by_email(params[:user][:email])
    puts "AAAAAAAAAAA"
    if user
      if user.confirmed?
        super
        puts "BBBBBBBBBBBBBB"
      else if DateTime.now < user.created_at + 7.days
        super
        puts "CCCCCCCCCCCCCC"
      else if DateTime.now > user.created_at + 7.days
        puts "DDDDDDDDDD"
        render json: { status: 403, notice: 'Email not confirmed' }
        user.send_confirmation_instructions
           end
      end
    end
  end
    else
      render json: { status: 404, notice: 'Email not found' }
    end
  end
  end