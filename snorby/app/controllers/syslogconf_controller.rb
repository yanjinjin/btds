# -*- coding: utf-8 -*-
class SyslogconfController < ApplicationController

  require 'yaml'

  attr_accessor :type
  attr_accessor :ip
  attr_accessor :port
  @@path = "/etc/suricata/"
  @@name = "suricata.yaml"

  def index
    @ip = "N/A"
    @port = "514"
    @type = nil
    get_fast_info
    get_json_info
    respond_to do |format|
      format.html
    end
  end

  def update
    ip = params[:ip]
    port = params[:port]
    type = params[:type]
    info = nil
    flag = true
     if ip == nil || ip == ""
      flag = false
      info = "缺少ip"
    end
    if port == nil || port == ""
      #port = "514"
       falg = false
       info = "缺少端口"
    else
      begin
        port = port.to_i
        if port > 65535 || port < 0
          flag = false;
          info = "端口号必须介于0~65535之间"
        end
      rescue
        flag = false
        info = "端口号异常"
      end
    end
    case type
    when "s"
      if flag
        use_json_log(ip,port)
        close_fast_log
        reset_json_log
        reset_fast_log
      end       
    when "b"
      if flag
        use_fast_log(ip,port)
        close_json_log
        reset_json_log
        reset_fast_log
      end
    when "n"
      close_log
      reset_json_log
      reset_fast_log
      info = "日志关闭"
    else
      flag = false
      info = "发生异常"  
    end
    if flag
      info = "设置成功"
    end 
    respond_to do |format|
      format.html {redirect_to syslogconf_path, :notice => info}
    end
  end

  def getYAML(path)
    data = YAML.load_file(path)
  end

  def inputhead(path)
    file = File.open(path, "w")
    file.puts('%YAML 1.1')
    file.close
  end
  
  def close_log
    close_json_log
    close_fast_log
  end

  def use_json_log(ip, port)
    `sed -i '/%YAML 1.1/d' #{@@path+@@name}`
    data = getYAML(@@path+@@name)
    #puts data["outputs"][1]["eve-log"]["enabled"]
    data["outputs"][1]["eve-log"]["enabled"] = true
    data["outputs"][1]["eve-log"]["host"] = ip
    data["outputs"][1]["eve-log"]["port"] = port
    inputhead(@@path+@@name)
    File.open(@@path+@@name, 'a') {|f| f.write data.to_yaml}
  end

  def use_fast_log(ip, port)
    `sh #{Rails.root}/shell/remotelog.sh #{ip} #{port}`
  end

  def close_json_log
    `sed -i '/%YAML 1.1/d' #{@@path+@@name}`
    data = getYAML(@@path+@@name)
    data["outputs"][1]["eve-log"]["enabled"] = false
    inputhead(@@path+@@name)
    File.open(@@path+@@name, 'a') {|f| f.write data.to_yaml}
  end
  
  def close_fast_log
    `sh #{Rails.root}/shell/remotelog.sh '#' '#'`
  end

  def get_json_info
    data = getYAML(@@path+@@name)
    flag = data["outputs"][1]["eve-log"]["enabled"]
    if flag
      @type = "s"  
      @ip = data["outputs"][1]["eve-log"]["host"]
      @port = data["outputs"][1]["eve-log"]["port"]
    end
  end
  
  def get_fast_info
    str = `sed -n p /etc/suricata/barnyard2.conf | grep "output alert_syslog_full" | awk -F , '{print $2,$4}'`
    if str.size > 0
      @type = "b"
      @ip = str.split(" ")[1]
      @port = str.split(" ")[3]
    end
  end

  def reset_json_log
    str = `ps -ef | grep suricata.yaml | awk '{print $2}'`.to_s
    ids = str.split("\n")
    ids.each {|id| `kill -9 #{id}`}
  end

  def reset_fast_log
    str = `ps -ef | grep barnyard2 | awk '{print $2}'`.to_s
    ids = str.split("\n")
    ids.each {|id| `kill -9 #{id}`}
  end

end
