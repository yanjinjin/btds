#encoding:utf-8
class RegistrationsController < Devise::RegistrationsController
  include Devise::Controllers::InternalHelpers
  
  before_filter :require_administrative_privileges, :only => [:create]

  def new
    build_resource({})
    render_with_scope :new
  end

  def create

    build_resource

    if resource.save
      if params[:user][:avatar].blank?
        redirect_to edit_user_registration_path, :notice => "用户创建成功."
      else
        render :template => "users/registrations/crop"
      end
    else
      clean_up_passwords(resource)
      render_with_scope :new
    end

  end

  def update
    method = (Snorby::CONFIG[:authentication_mode] == "database") ? "update_with_password" :  "update"
    if resource.send(method, params[resource_name])
      
      if params[resource_name]['avatar'].blank?
        
        resource.reprocess_avatar
        
        set_flash_message :notice, :updated
	    @log = Log.new
		time = Time.new
		@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
	    #@time=Time.now
	    #@log[:optime]=@time.strftime("%Y-%m-%d %H:%M:%S")
	    @log[:ip]=request.remote_ip
	    @log[:username]=@current_user
	    @log[:opobject]="更改用户设置"
	    @log[:opdetail]="更改用户设置成功"
	    @log.save
        redirect_to edit_user_registration_path
      else
        render :template => "users/registrations/crop"
      end

    else
      clean_up_passwords(resource)
      redirect_to edit_user_registration_path
    end
  end

end
