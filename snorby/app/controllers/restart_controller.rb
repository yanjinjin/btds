#encoding:utf-8
class RestartController < ApplicationController
  def index
  end

  def show
  end

  def update
	    @log = Log.new
	    time = Time.new
		@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
	    @log[:ip]=request.remote_ip
	    @log[:username]=@current_user
	    @log[:opobject]="重启系统"
	    @log[:opdetail]="执行重启成功"
	    @log.save
	redirect_to :action =>'index'
	exec=`init 6`
  end

end
