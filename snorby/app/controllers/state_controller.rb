#require "singleton"
class StateController < ApplicationController
  #include Singleton
  layout "blank"
  @@file = "#{Rails.root}/tmp/sys_status/status"
  @@path = "#{Rails.root}/tmp/sys_status"
  def initialize
    super
  end
  
  def index
    Snorby::Worker.init
    if FileTest::exist?(@@file)
      file = File.open(@@file)
      str = file.read.split(" ")
      @cpu = str[0].to_f.round(1)
      @ram = str[1].to_f.round(1)
      @disk = str[2].to_f.round(1)
      file.close
    else
      @cpu = 0
      @ram = 0
      @disk = 0
    end #e if
    @str = {:cpu => @cpu, :ram => @ram, :disk => @disk}
    respond_to do |format|
      format.json { render :json => @str }
    end
  end#e def
end#e class
