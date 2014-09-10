module Account
  class AccountController < ApplicationController
    before_filter :authenticate_user!
    layout 'account'

    def dashboard
      @notifications = current_user.notifications.order("created_at DESC").page(params[:page])
    end
  end
end
