class RulesController < ApplicationController
  # GET /rules
  # GET /rules.json
  # total num of rules
  attr_accessor :count
  attr_accessor :version
  attr_accessor :timestamp
  attr_accessor :total
  @@path = "/etc/suricata/rules/"
  @@filename = "version"
  def index
    @rules ||= Rule.all.page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:id.asc])
    p = @@path + @@filename
    if FileTest::exist?(p)
      file = File.new(p)
      file.each_line {|line| str = line.split(":")
        if str[0] == "version"
          @version = str[1]
        elsif str[0] == "date"
          @timestamp = str[1]
        elsif str[0] == "total"
          @total = str[1]
        end  
      }
    end
    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  # GET /rules/1
  # GET /rules/1.json
  def show
    @rule = Rule.get(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @rule }
    end
  end
end
