# -*- coding: utf-8 -*-
class NetFlowsController < ApplicationController

  $rangeList = [{"value" => "1h", "text" => "1小时/1分钟"},{"value" => "1d", "text" => "24小时/30分钟"},{"value" => "1M", "text" => "1个月/1天"}]

  def index
    ethname = NetworkController::getNICname
    data = `#{Rails.root}/shell/changeip.sh`
    @data_a = []
    wangka = data.split("#")
    wangka.each do |wang|
      w = wang.split(",")
      if w[0] == ethname
        #w[0] = "管理口"
        @data_a  << w
      end
    end

    @net_flow = NetFlow.last
    if @net_flow.nil?
      @current_speed = 0
      @current_pkts = 0
    else
      @current_speed = @net_flow.decoder_bytes
      @current_pkts = @net_flow.decoder_pkts
    end

    @selected = nil
    if params && params[:time] && params[:time][:range]
      range = params[:time][:range]
      @selected = params["time"] ? params["time"]["range"] : "1h"
    else
      range = "1h"
      @selected = "1h"
    end
    
    start, interval, unit, @x_interval = nil, nil, nil, nil
    case range
    when "1d"
      unit = "30分钟"
      start = Time.now - 1.day
      interval = 30.minute
      @x_interval = 3600000
      list = NetFlow.query_by_sql(sql_by_time(start, Time.now))
    when "1M"
      unit = "天"
      start = Time.now.midnight - 30.day
      interval = 1.day
      @x_interval = 259200000
      list = NetFlow.query_by_sql(sql_by_time(start, Time.now))
    else
      unit = "分钟"
      start = Time.now - 1.hour
      interval = 1.minute
      @x_interval = 300000
      list = NetFlow.query_by_sql(sql_by_time(start, Time.now))
    end
    @data = []
    @data.push(to_data(list, start, interval, unit))
    @start = start.to_i*1000
    respond_to do |format|
      format.html
      format.json {
        render json: {:net_flow => @net_flow, :current_speed => @current_speed, :current_pkts => @current_pkts, :select => @select, :data => @data.to_json, :start => @start, :interval => interval}
      }
    end
  end
  
  #format net_flow_list to data
  def to_data(list, start_time, interval, unit)
    #hash = {:type => "line", :name => "b/#{unit}", :pointInterval => interval*1000, :pointStart => start_time.to_i*1000, :data => []}
    hash = {:name => "b/#{unit}", :data => []}
    time_point, flow_count = start_time, 0
    if list.size > 0
      list.each do |nf|
        if nf.date <= time_point
          flow_count = flow_count + nf.decoder_bytes
        else
          time_point = time_point + interval
          #hash[:data].push(flow_count)
          hash[:data].push([time_point.to_i*1000, flow_count])
          flow_count = 0
          redo
        end
      end
      #hash[:data].push(flow_count)
      hash[:data].push([time_point.to_i*1000, flow_count])
    end

    #for test
=begin
    while hash[:data].size < 29
      time_point = time_point + interval
      hash[:data].push([time_point.to_i*1000, 0])
    end
=end
    return hash
  end

  def sql_by_time(start_time, end_time)
    sql = "select * from net_flows where 1=1"
    if start_time != nil
      sql = sql + " and date >= '#{start_time}'"
    end
    if end_time != nil
      sql = sql + " and date <= '#{end_time}'"
    end
    sql = sql + ";"
    return sql
  end

end
