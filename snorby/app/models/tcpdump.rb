# -*- coding: utf-8 -*-
class Tcpdump

  include DataMapper::Resource

  property :id, Serial
  
  # 0 = unstart 
  # 1 = started
  # 2 = finished
  property :pid, Integer
  property :status, String, :default => 0
  property :name, String, :required => true
  property :run_at, DateTime
  property :stop_at, DateTime
  property :src_ip, String
  property :dst_ip, String
  property :src_port, String
  property :dst_port, String
  property :protocol, String
  property :plan_time, String
  property :plan_size, String
  property :plan_start, Boolean
  property :plan_start_time, DateTime
  
  def use_time
    if(stop_at != nil && run_at != nil && status == "2")
      seconds = stop_at.to_i-run_at.to_i
      return getUseTime(seconds, 86400)
    else
      return "N/A"  
    end
  end

  def size
    if status == "2" && FileTest.exist?("/tmp/static_#{id}.pcap")
      size = File.size("/tmp/static_#{id}.pcap")
      size, level = getSize(size, 0)
      case level
      when 0
        tmp = "b"
      when 10
        tmp = "k"
      when 20
        tmp = "M"
      when 30
        tmp = "G"
      when 40
        tmp = "T"
      when 50
        tmp = "P"
      end
      return "#{size}#{tmp}"
    else
      return 0
    end
  end

  def getSize(size, level)
    return (size/(1 << level))>=1024 ? getSize(size, level+10) : [size/(1 << level), level]
  end

  def getUseTime(seconds, level)
    case level
    when 1
      return seconds==0 ? "" : "#{seconds}秒"
    when 60
      str = "分"
      next_level = 1
    when 3600
      str = "小时"
      next_level = 60
    when 86400
      str = "天"
      next_level = 3600
    end
    value = seconds/level
    return value >= 1 ? "#{value}"+str+getUseTime(seconds-value*level, next_level) : getUseTime(seconds, next_level)
  end
end
