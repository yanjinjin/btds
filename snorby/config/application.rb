# -*- coding: utf-8 -*-
require File.expand_path('../boot', __FILE__)

#require 'rails/all'
require 'sprockets/railtie'
require 'action_controller/railtie'
require 'dm-rails/railtie'
require 'action_mailer/railtie'
require 'rails/test_unit/railtie'
require 'timezone_local'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Snorby

  # Check Ruby Version
  unless RUBY_VERSION.match(/^1.9/)
    puts "Snorby requires Ruby version 1.9.x"
    puts "We suggest using Ruby Version Manager (RVM) https://rvm.io/ to install the newest release"
    exit 1
  end

  # Check For snorby_config.yml
  unless File.exists?("config/snorby_config.yml")
    puts "Snorby Configuration Error"
    puts "* Please EDIT and rename config/snorby_config.yml.example to config/snorby_config.yml"
    exit 1
  end
  
  # Check For database.yml
  unless File.exists?("config/database.yml")
    puts "Snorby Configuration Error"
    puts "* Please EDIT and rename config/database.yml.example to config/database.yml"
    exit 1
  end

  # Snorby Environment Specific Configurations
  raw_config = File.read("config/snorby_config.yml")
  CONFIG = YAML.load(raw_config)[Rails.env].symbolize_keys

  # Default authentication to database
  unless CONFIG.has_key?(:authentication_mode)
    CONFIG[:authentication_mode] = "database"
  end

  # default base uri is none...
  unless CONFIG.has_key?(:baseuri)
    CONFIG[:baseuri] = ""
  end

  class Application < Rails::Application

    config.threadsafe!
    config.dependency_loading = true
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    PDFKit.configure do |config|
      config.wkhtmltopdf = Snorby::CONFIG[:wkhtmltopdf]
      config.default_options = {
          :page_size => 'Legal',
          :print_media_type => true
        }
    end
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/
    # -- all .rb files in that directory are automatically loaded.

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    #

    time_zone = CONFIG[:time_zone] # set your local time zone here. use rake time:zones:local to choose a value, or use UTC.

    unless time_zone
      # try to detect zone using
      detected_time_zone = TimeZone::Local.get
   
      if detected_time_zone
        time_zone = detected_time_zone.name
        puts "No time_zone specified in snorby_config.yml; detected time_zone: #{time_zone}"
      else
        puts "*** Warning:  no time zone is set in config/application.rb. Using UTC as the default time and behavior may be unexpected."
        puts "*** You can manually set the timezone in config/snorby_config.yml in the time_zone setting."
        puts "*** Valid time zones can be found by running `rake time:zones:local`"
        time_zone = "UTC"
      end
    end

    config.time_zone = time_zone

    DataMapper::Zone::Types.storage_zone = time_zone
    CONFIG[:time_zone] = time_zone unless CONFIG[:time_zone]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
     #config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
     #config.i18n.default_locale = :'zh-CN'

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    
    config.generators do |g|
      g.orm             :data_mapper
      g.template_engine :erb
      g.test_framework  :rspec
    end
    
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable SSL if it was enabled in the configuration
    if CONFIG.has_key?(:ssl) && CONFIG[:ssl]
      config.force_ssl = true
      config.action_mailer.default_url_options = { :protocol => 'https', :host => Snorby::CONFIG[:domain] }
    else
      config.action_mailer.default_url_options = { :host => Snorby::CONFIG[:domain] }
    end

#2015/8/17 Multithreading

    def sysStatus
      while true
        cpu = `bash shell/cpu.sh`
        ram = `bash shell/ram.sh`
        disk = `bash shell/disk.sh`
        if !FileTest::exist?("#{Rails.root}/tmp/sys_status/status")
          `touch "{#{Rails.root}/tmp/sys_status/status"}`
        end
        `echo "#{cpu} #{ram} #{disk}" > #{"#{Rails.root}/tmp/sys_status/status"}`
      end
    end

    def killBackTcpdump
      sleep 15
      # kill back tcpdump
      while true
        count = `ps -ef|grep tcpdump|grep -v grep|grep auto|wc -l`.split("\n")[0].to_i
        if count > 100
          killTcpByTimeOrder(count-100)
        else
          killTcpByTimeOrder(0)
        end
        # repair the tcpdump jobs which closed unexpectedly
        begin
          list = Tcpdump.find_by_sql("select * from tcpdumps where status = '1'")
          list.each do |tcpdump|
            pid = tcpdump.pid
            str = `ps -ef|grep tcpdump|grep -v grep|grep static|grep #{tcpdump.pid}`
            if str == ""
              tcpdump.update ({:stop_at => DateTime.now, :status => "2", :pid => nil})
            end
          end
        rescue

        end
        sleep 1800
      end

    end

    def killTcpByTimeOrder(amount=0)
      str = `ps -eo pid,etime,cmd|grep tcpdump|grep auto|awk '{print $1"|"$2}'`.split("\n")
      if amount == 0 #kill the tcpdumps which etime more than 24hours                        
        str.each do |l|
          line = l.split("|")
          if (line[1]=~/\d{1,2}-\d{2}/) != nil
            `kill #{line[0]}`
          end
        end
      else #kill the tcpdumps order by etime
        list = []
        str.each do |l|
          pid, time = l.split("|")
          if (time=~/\d{1,2}-\d{2}/) != nil
            `kill #{pid}`
             amount = amount - 1
          else
             time = toSeconds(time)
             list << [pid,time]
          end
        end
        quickSortByTime(list)
        i = 0
        while i < amount
          `kill #{list[i][0]}`
          i = i + 1
        end
      end
    end

    def toSeconds(time)
      seconds = 0
      tmp = time.split(":")
      if tmp.size == 2
        seconds = tmp[0].to_i*60+tmp[1].to_i
      elsif tmp.size == 3
        seconds = tmp[0].to_i*3600+tmp[1].to_i*60+tmp[2].to_i
      end
      return seconds
    end

    def quickSortByTime(list)
      return [] if (x,*xs=list).empty?
      more, less = xs.partition{|y| y[1] > x[1]}
      quickSortByTime(more) + [x] + quickSortByTime(less)
    end

    def killFrontTcpdump
      sleep(10)
      while true
        sleep(5)
        begin
          file_size = Tcpdump.find_by_sql("select * from tcpdumps where status = '1' AND plan_size != ''")
          file_size.each do |tcpdump|
            size = File.size("/tmp/static_#{tcpdump.id}.pcap").to_i
            #puts "file_size : #{size} b"
            if size >= tcpdump.plan_size.to_i * 1024 * 1024
              killTcpdump(tcpdump)
            end
          end
          plan_time = Tcpdump.find_by_sql("select * from tcpdumps where status = '1' AND plan_time != ''")
          plan_time.each do |tcpdump|
            etime = (Time.now - tcpdump.run_at).to_i
            if etime >= tcpdump.plan_time.to_i
              killTcpdump(tcpdump)
            end
          end
          timing = Tcpdump.find_by_sql("select * from tcpdumps where status = '3' AND plan_start_time is not null")
          now = Time.now
          timing.each do |tcpdump|
            #puts "timing : #{tcpdump.name}"
            if now >= tcpdump.plan_start_time
              startTcpdump(tcpdump)
            end
          end
        rescue Exception => e
          puts e
        end
      end
    end

    def killTcpdump(tcpdump)
      pid = tcpdump.pid
      begin
        GLOBAL_MUTEX.lock
          pipe = GLOBAL_HASH[:pipe_hash][pid]
          `kill #{pid}`
          if pipe != nil
            pipe.close
          end
          tcpdump.update ({:stop_at => DateTime.now, :status => "2", :pid => nil})
          if GLOBAL_HASH[:pipe_hash].has_key?(pid)
            GLOBAL_HASH[:pipe_hash].delete(pid)
          end
        GLOBAL_MUTEX.unlock
      rescue Exception => e
        puts e
        GLOBAL_MUTEX.unlock
      end
    end
   
    def startTcpdump(tcpdump)
      str = TcpdumpsController.getCommand(tcpdump)
      pipe = IO.popen("#{str}")
      pid = pipe.pid
      GLOBAL_MUTEX.synchronize do
        GLOBAL_HASH[:pipe_hash][pid] = pipe
        tcpdump.update ({:run_at => DateTime.now, :status => "1", :pid => pid})
      end
    end

    def monitorLogAnalyze
      net_flow = nil
      lastNF = nil
      while true 
        begin
          sleep 10
          fileList = monitorLogFileName
          lastTime = monitorLogLastDate
          fileList.each do |fileName|
            if name_to_date(fileName) > lastTime
              flag_new = false
              file = File.open("#{fileName}")
              file.each_line do |line|
                if line.start_with?("Date:")
                  str = line.split(" ")
                  ymd = str[1].split("/")
                  hms = str[3].split(":")
                  #time = Time.new(ymd[2].to_i, ymd[0].to_i, ymd[1].to_i, hms[0].to_i, hms[1].to_i, hms[2].to_i, "+08:00")
                  time = Time.new(ymd[2].to_i, ymd[0].to_i, ymd[1].to_i, hms[0].to_i, hms[1].to_i, hms[2].to_i)
                  if lastTime.nil? || time - lastTime > 8
                    net_flow = NetFlow.new
                    flag_new = true
                    net_flow.date = time
                  else
                    flag_new = false
                  end
                elsif flag_new && line.start_with?("decoder.bytes")
                  strs = line.split("|")
                  attr = strs[0].split(".")
                  value = strs[2].chomp.to_i
                  net_flow.method("#{attr[0]}_#{attr[1].delete(" ")}=").call (value*8)
                elsif flag_new && (line.start_with?("decoder.pkts", "decoder.bytes", "decoder.ipv4", "decoder.ipv6", "decoder.tcp", "decoder.udp", "decoder.icmpv4", "decoder.icmpv6", "decoder.gre", "tcp.sessions", "tcp.syn")) && (!line.start_with?("decoder.ipv4_in_ipv6", "decoder.ipv6_in_ipv6", "tcp.synack"))
                  strs = line.split("|")
                  attr = strs[0].split(".")
                  value = strs[2].chomp.to_i
                  net_flow.method("#{attr[0]}_#{attr[1].delete(" ")}=").call value
                elsif flag_new && line.start_with?("tcp.rst") #last data of one record
                  strs = line.split("|")
                  attr = strs[0].split(".")
                  value = strs[2].chomp.to_i
                  net_flow.method("#{attr[0]}_#{attr[1].delete(" ")}=").call value
                  if lastNF == nil
                    lastNF = net_flow
                    net_flow = NetFlow.new
                    net_flow.date = lastNF.date
                    net_flow.save
                  elsif
                    tmp = NetFlow.substract(net_flow, lastNF)
                    lastNF = net_flow
                    tmp.save
                  end
                  lastTime = net_flow.date
                  flag_new = false
                  #net_flow = nil
                end
              end
            end
            deleteFile(fileName)
          end
        rescue Exception => e
          puts e
        end
      end
    end
    
    def deleteFile(fileName)
      fileDay = fileName.split("/")[4].split("-")
      time = Time.now
      if time.year > fileDay[0].to_i
        `rm -f #{fileName}`
      elsif time.month > fileDay[1].to_i
        `rm -f #{fileName}`
      elsif time.day > fileDay[2].to_i + 1
        `rm -f #{fileName}`
      end
    end

    def name_to_date(fileName)
      strs = fileName.split("-")
      str1 = strs[0].split("/")
      year = str1[str1.size-1]
      time = Time.new(year.to_i, strs[1].to_i, strs[2].to_i, strs[3].to_i, 59, 59)
      return time
    end

    #get the lastest record date in database
    def monitorLogLastDate
      last = NetFlow.last
      return last.nil? ? nil : last.date
    end
    
    #according to the lastest record date , return the file name
    def monitorLogFileName
      fileList = []
      lastDate = monitorLogLastDate
      list = `find #{MONITOR_LOG_PATH} -regex ".*/*stats.log"`.split("\n")
      return quickSortByFileName(list)
=begin
      if lastDate.nil?
        return quickSortByFileName(list)
      else
        lastDateFormate = lastDate.strftime("#{MONITOR_LOG_PATH}/%Y-%m-%d-%H")
        list.each do |l|
          if isBigger?(l, lastDateFormate)
            fileList << l
          end
        end
        return quickSortByFileName(fileList)
      end
=end
    end

    def quickSortByFileName(list)
      return [] if (x,*xs=list).empty?
      more, less = xs.partition{|y| !isBigger?(y,x) }
      quickSortByFileName(more) + [x] + quickSortByFileName(less)
    end

    def isBigger?(y, x)
      begin
        y = y.split("-")
        if y[0].length > 4
          y[0] = y[0].split("/")[4]
        end
        x = x.split("-")
        if x[0].length > 4
          x[0] = x[0].split("/")[4]
        end
        if y[0].to_i > x[0].to_i
          return true
        elsif y[1].to_i > x[1].to_i
          return true
        elsif y[2].to_i > x[2].to_i
          return true
        elsif y[2].to_i == x[2].to_i && y[3].to_i >= x[3].to_i
          return true
        else
          return false
        end
      rescue Exception => e
        puts e
        return false 
      end
    end

    MONITOR_LOG_PATH = "/var/log/suricata"
    GLOBAL_HASH = {}
    GLOBAL_HASH[:pipe_hash] = {}
    GLOBAL_MUTEX = Mutex.new
    GLOBAL_HASH[:sys_status_thread] = Thread.new{sysStatus()}
    GLOBAL_HASH[:back_tcpdump_thread] = Thread.new{killBackTcpdump()}
    GLOBAL_HASH[:front_tcpdump_thread] = Thread.new{killFrontTcpdump()}
    Thread.new{monitorLogAnalyze()}
  end

end
