class WelcomeController < ApplicationController
 
  def index
    if params[:subscription] == 'success'
      flash.now[:notice] = "Welcome! Your subscription has been activated. You now have access to all features."
    elsif params[:subscription] == 'canceled'
      flash.now[:alert] = "Subscription canceled. You can try again anytime."
    end
  end
end
