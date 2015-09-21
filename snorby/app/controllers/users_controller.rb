#encoding:utf-8
class UsersController < ApplicationController

  before_filter :require_administrative_privileges, :only => [:index, :add, :new, :remove]
  
  def index
    @users = User.all.page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:id.asc])
  end

  def new
    @user = User.new
  end
  
  def add
    @user = User.create(params[:user])
	@user[:timezone]="PRC"
    if @user.save
      @log = Log.new
      time = Time.new
	  @log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
      @log[:ip]=request.remote_ip
      @log[:username]=@current_user
      @log[:opobject]="添加用户"
      @log[:opdetail]="添加用户成功"
      @log.save
      redirect_to users_path
    else
      render :action => 'new'
    end
  end
  
  def remove
    @user = User.get(params[:id])
    @user.destroy!
    @log = Log.new
    time = Time.new
	@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="删除用户"
    @log[:opdetail]="删除用户成功"
    @log.save
    redirect_to users_path, :notice => "用户删除成功"
  end

  def toggle_settings
    @user = User.get(params[:user_id])
    
    if @user.update(params[:user])
      render :json => {:success => '用户信息更新成功.'}
    else
      render :json => {:error => '更改用户属性时出现了错误.'}
    end
    
  end

end
