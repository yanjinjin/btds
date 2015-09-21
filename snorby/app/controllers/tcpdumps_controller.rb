# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-

class TcpdumpsController < ApplicationController

  @@path = "/tmp"  
  @@global_hash = Snorby::Application::GLOBAL_HASH
  @@global_mutex = Snorby::Application::GLOBAL_MUTEX

  def index
    @tcpdumps = Tcpdump.all.page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:id.asc])
=begin
    puts "================================"
    puts @@global_hash[:pipe_hash].keys
    puts "================================"
=end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tcpdumps }
    end
  end

  def show
    @tcpdump = Tcpdump.get(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tcpdump }
    end
  end

  def new
    @tcpdump = Tcpdump.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tcpdump }
    end
  end

  def edit
    @tcpdump = Tcpdump.get(params[:id])
  end

  def create
    @tcpdump = Tcpdump.new(params[:tcpdump])
    flag = true
    if (@tcpdump.plan_size.nil? || @tcpdump.plan_size == "") && (@tcpdump.plan_time.nil? || @tcpdump.plan_time =="")
      flag = false
      flash[:notice] = "抓包时间和文件大小必须填写其中一项"
    end
    if @tcpdump.plan_start 
      @tcpdump.status = "3"
      if @tcpdump.plan_start_time.blank?
        @tcpdump.plan_start_time = nil
        flag = false
        if flash[:notice].blank?
          flash[:notice] = "未设置启动时间,任务无法自启"
        end
      end
    else
      if @tcpdump.plan_start_time.blank?
        @tcpdump.plan_start_time = nil
      end
    end
    respond_to do |format|
      if flag && @tcpdump.save
        format.html { redirect_to '/tcpdumps', notice: '创建成功' }
      else
        puts @tcpdump.errors.full_messages
        format.html { redirect_to action: "new"}
      end
    end
  end

  def update
    @tcpdump = Tcpdump.get(params[:id])
    flag = true
    if (params[:tcpdump][:plan_size].nil? || params[:tcpdump][:plan_size] == "") && (params[:tcpdump][:plan_time].nil? || params[:tcpdump][:plan_time] =="")
      flag = false
      flash[:notice] = "抓包时间和文件大小必须填写其中一项"
    end
    if params[:tcpdump][:plan_start] == "true" && params[:tcpdump][:plan_start_time].blank?
      flag = false
      if flash[:notice]
        flash[:notice] = "未设置启动时间,任务无法自启"
      end
    end    
    if @tcpdump.status == "0" || @tcpdump.status == "3"
      if params[:tcpdump][:plan_start_time].blank?
        params[:tcpdump][:plan_start_time] = nil
      end
      if params[:tcpdump][:plan_start] == "true"
        params[:tcpdump][:status] = "3"
      else
        params[:tcpdump][:status] = "0"
      end
    end
    respond_to do |format|
      if flag && @tcpdump.update(params[:tcpdump])
        format.html { redirect_to '/tcpdumps', notice: '更新成功' }
      else
        puts @tcpdump.errors.full_messages
        format.html { redirect_to "/tcpdumps/#{params[:id]}/edit" }
      end
    end
  end

  def destroy
    `rm #{@@path}/static_#{params[:id]}.pcap`
    @tcpdump = Tcpdump.get(params[:id])
    if @tcpdump.status != "1"
      @tcpdump.destroy
    end
    respond_to do |format|
      format.html { redirect_to tcpdumps_url }
      format.json { head :ok }
    end
  end

  def start
    if @@global_hash[:pipe_hash].size >= 5
      flash[:notice] = "抓包任务过多，请关闭部分任务后再启动新的任务"
    else
      puts "Ready to work"
      if !File.directory?("#{@@path}")
        `mkdir #{@@path}`
      end
      @tcpdump = Tcpdump.get(params[:id])
      puts @tcpdump.name
    
      str = TcpdumpsController.getCommand(@tcpdump)

      pipe = IO.popen("#{str}")
      pid = pipe.pid
      @@global_mutex.synchronize do
        @@global_hash[:pipe_hash][pid] = pipe
        @tcpdump.update ({:run_at => DateTime.now, :status => "1", :pid => pid})
      end
    end
    respond_to do |format|
      format.html { redirect_to tcpdumps_url }
      format.json { head :ok }
    end
  end

  def stop
    @tcpdump = Tcpdump.get(params[:id])
    if @tcpdump.status == "1"
      pid = @tcpdump.pid
      @@global_mutex.synchronize do
        begin
          pipe = @@global_hash[:pipe_hash][pid]
          `kill #{pid}`
          pipe.close
          if @@global_hash[:pipe_hash].has_key?(pid)
            @@global_hash[:pipe_hash].delete(pid)
          end
        rescue Exception => e
          puts e
        end
        @tcpdump.update ({:stop_at => DateTime.now, :status => "2", :pid => nil})
      end
    else
      flash[:notice] = "任务已被关闭"
    end 
    respond_to do |format|
      format.html { redirect_to tcpdumps_url }
      format.json { head :ok }
    end
  end
  
  def sendfile
    str = "#{@@path}/static_#{params[:id]}.pcap"
    @tcpdump = Tcpdump.get(params[:id])
    if FileTest.exists? str
      send_file(str, :filename => "#{@tcpdump.name}.pcap")
    else
      respond_to do |format|
        format.html { redirect_to '/tcpdumps', notice: '文件不存在' }
      end
    end
  end
  
  def TcpdumpsController.getCommand(tcpdump)
    puts "get str!!!!!!!!!!!!!!!!!!"
    count = NetworkController.getNICnum
    str = "tcpdump"
=begin
    if tcpdump.plan_size.nil? || tcpdump.plan_size == "" 
      str = str + " -c 10000"
    end
=end
    if count == 7
      str = str + " -i eth6"
    elsif count == 6 || count == 1
      str = str + " -i eth0"
    end
    if tcpdump.protocol == nil
      str = str + "tcp -s 0"
    else
      str = str + " #{tcpdump.protocol} -s 0"
    end
    if tcpdump.src_ip != nil && tcpdump.src_ip != ""
      str = str + " and src host #{tcpdump.src_ip}"
    end
    if tcpdump.src_port != nil && tcpdump.src_port != ""
      str = str + " and src port #{tcpdump.src_port}"
    end
    if tcpdump.dst_ip != nil && tcpdump.dst_ip != ""
      str = str + " and dst host #{tcpdump.dst_ip}"
    end
    if tcpdump.dst_port != nil && tcpdump.dst_port != ""
      str = str + " and dst port #{tcpdump.dst_port}"
    end
    str = str + " -w #{@@path}/static_#{tcpdump.id}.pcap"
    return str
  end

end
