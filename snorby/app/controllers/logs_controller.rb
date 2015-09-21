#encoding:utf-8
class LogsController < ApplicationController
  require 'csv'
  require 'find'
  # GET /logs
  # GET /logs.json
  respond_to :html, :xml, :json, :js, :csv

  
  def index
    @logs ||= Log.all.page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:id.desc])
    
    respond_to do |format|
      format.html {render :layout => true}
      format.js
    end
  end

  # GET /logs/1
  # GET /logs/1.json
  def show
    @log = Log.get(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @log }
    end
  end

  # GET /logs/new
  # GET /logs/new.json
  def new
    @log = Log.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @log }
    end
  end

  # GET /logs/1/edit
  def edit
    @log = Log.get(params[:id])
  end

  # POST /logs
  # POST /logs.json
  def create
    @log = Log.new(params[:log])
    @time=Time.now
    @log[:optime]=@time
    @log[:ip]="test"
    @log[:username]="suncle"
    @log[:opobject]="login"
    @log[:opdetail]="login s"
    respond_to do |format|
      if @log.save
        format.html { redirect_to @log, notice: 'Log was successfully created.' }
        format.json { render json: @log, status: :created, location: @log }
      else
        format.html { render action: "new" }
        format.json { render json: @log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /logs/1
  # PUT /logs/1.json
  def update
    @log = Log.get(params[:id])

    respond_to do |format|
      if @log.update(params[:log])
        format.html { redirect_to @log, notice: 'Log was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /logs/1
  # DELETE /logs/1.json
  def destroy
    @log = Log.get(params[:id])
    @log.destroy

    respond_to do |format|
      format.html { redirect_to logs_url }
      format.json { head :ok }
    end
  end

  #导出为csv文件
  def export
     @log =Log.find(:all)
     head = 'EF BB BF'.split(' ').map{|a|a.hex.chr}.join()
     csv_string = CSV.generate do |csv|
        csv << ["\xEF\xBB\xBFID","操作时间","用户","IP","操作对象","操作结果"]
        @log.each do |l|
          csv << [l.id,l.optime,l.username,l.ip,l.opobject,l.opdetail]
        end
      end
      send_data csv_string,
		:type=>'text/csv; charset=utf-8; header=present',  
                :disposition => "attachment; filename=log_export.csv"
    @log = Log.new
    time = Time.new
	@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="导出日志"
    @log[:opdetail]="导出成功"
    @log.save
  end

  #日志备份
  def backup
     exec=`sh #{Rails.root}/shell/logs_backup.sh`
    @log = Log.new
    time = Time.new
	@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="备份日志"
    @log[:opdetail]="备份成功"
    @log.save
     redirect_to :action => 'showbak'
  end

  def showbak
     @filename=[]
     Dir.foreach("#{Rails.root}/public/logsbackup") do |file|
        if file !="."and file !=".."
           @filename << file
        end 
     end
     @filename=@filename.sort.reverse
  end

  #日志恢复
  def recovery
    #filename = "logs_backup20150313104717.sql"
    @filename = params[:filename]
    exec=`sh #{Rails.root}/shell/logs_recovery.sh #{@filename}`
    @log = Log.new
    time = Time.new
	@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="恢复日志"
    @log[:opdetail]="恢复成功"
    @log.save
    redirect_to :action => 'index'
  end

  #删除备份
  def delete
    @filename = params[:filename]
    exec=`sh #{Rails.root}/shell/logsbak_delete.sh #{@filename}`
    @log = Log.new
    time = Time.new
	@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="删除日志备份"
    @log[:opdetail]="删除日志备份成功"
    @log.save
    redirect_to :action => 'showbak'
  end

  #清空日志
  def empty
    Log.empty
    @log = Log.new
    time = Time.new
	@log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="清空日志"
    @log[:opdetail]="清空日志成功"
    @log.save
    redirect_to :action => 'index'
  end

end
