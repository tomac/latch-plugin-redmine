require_relative '../api/Latch'

class LatchAccountsController < ApplicationController
  unloadable


  def index
    @user = User.find(User.current.id)
    if (!@user.logged?)
      redirect_to '/login'
    else
      latch = LatchAccount.where(user_id: User.current.id).take(1)
      latch.length == 0 ?  @allowunpairing = false : @allowunpairing = true
    end

  end


  def pair
    appid = Setting.plugin_latch['latch_appid']
    secret = Setting.plugin_latch['latch_secret']
    token = params[:token]

    if (!token.empty?)
      api = Latch.new(appid.to_s, secret.to_s)
      pairResponse = api.pair(token.to_s)

      if (pairResponse != nil && pairResponse.data != nil)
        accountid = pairResponse.data["accountId"]


        latch = LatchAccount.new :user_id => User.current.id, :account_id => accountid
        latch.save

        flash[:notice] = 'Your account has been succesfully Paired'
      elsif (pairResponse.error.code == 206)
        flash[:error] = 'You have introduce an invalid token'
      else
        flash[:error] = 'Some problems encountered. Please try again later or contact administration team'
      end
    end
      redirect_to :action => 'index'

  end


  def unpair
    appid = Setting.plugin_latch['latch_appid']
    secret = Setting.plugin_latch['latch_secret']

    api = Latch.new(appid, secret)

    @latch = LatchAccount.where(user_id: User.current.id).first
    account_id = @latch.account_id


    pairResponse = api.unpair(account_id)
    if (pairResponse.error == nil)
      @latch.destroy
      flash[:notice] = 'Your account has been succesfully unpaired. Keep in mind that you can pair it again at any time.'
    else
      flash[:error] = 'Some problems encountered. Please try again later or contact administration team'
    end
    redirect_to :action => 'index'
  end


end
