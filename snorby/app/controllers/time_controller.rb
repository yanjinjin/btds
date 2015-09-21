#encoding:utf-8
class TimeController < ApplicationController

  attr_accessor :date
  attr_accessor :setTimeType
  @@path = "#{Rails.root}/tmp/ntp/"
  @@file = "service"
  def index
    date = Time.now
    @date = date.strftime("%Y-%m-%d %H:%M:%S")
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def update
    date = params[:date]
    if date['type'] != "" && date['type'].to_i == 0#sync by local
      setTimeByLocal(date)
    elsif date['type'].to_i == 1#sync by service
      setTimeByNTP
    else
      setTime(date)
    end
   
    respond_to do |format|
      format.html { redirect_to time_url }
      format.json { head :ok }
    end
  end

  def get_time
    date = Time.new
    @date = date.strftime("%Y-%m-%d %H:%M:%S")
    @str = {:time => @date }
    respond_to do |format|
      format.json { render :json => @str }
    end
  end

  def setTime(date)
    time = date['time']
    `date -s "#{time}"`
    @log = Log.new
    time = Time.new
    @log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="修改系统时间"
    @log[:opdetail]="修改时间成功"
    @log.save
  end

  def setTimeByLocal(date)
    time = Time.at(date['local'].to_i/1000)
    year = time.year
    month = time.month
    day = time.day
    hour = time.hour
    minute = time.min
    second = time.sec
    `date -s "#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}"`
    @log = Log.new
    time = Time.new
    @log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="同步本地时间"
    @log[:opdetail]="同步本地时间成功"
    @log.save
  end

  def setTimeByNTP()
    result = ""
    if File.directory?(@@path) && FileTest::exist?(@@path+@@file)
      text = File.open(@@path+@@file)
      text.each_line do |line|
        if result == "" || result.count("adjust time") == 0
          result = `ntpdate #{line.strip}`
        end
      end
      text.close
    else
      result = `ntpdate pool.ntp.org`
      if !File.directory?(@@path)
        `mkdir #{@@path}`
      end
      if !FileTest::exist?(@@path+@@file)
        `touch #{@@path}#{@@file}`
        `echo pool.ntp.org > #{@@path}#{@@file}`
      end
    end
    @log = Log.new
    time = Time.new
    @log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
    @log[:ip]=request.remote_ip
    @log[:username]=@current_user
    @log[:opobject]="同步NTP时间"
    @log[:opdetail]="同步NTP时间成功"
    @log.save
    if result == "" || result.count("adjust time") == 0
      raise "ntp service is not available, please try again later."
    end
  end
end
