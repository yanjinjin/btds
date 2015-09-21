#encoding:utf-8
#require ActiveRecord::Base
class NetworkController < ApplicationController
   include DataObjects::Pooling
   def show
     count = getNICnum
     ethname = " ";
     if count == 7 
       ethname = "eth6"
     elsif count == 6 || count == 1
       ethname = "eth0"
     end
     @data_a = []
     @data = `#{Rails.root}/shell/changeip.sh`
     @wangka = @data.split("#")
     @wangka.each do |wang|
       w = wang.split(",")
       #puts w[0]
       if w[0] == ethname
         w[0] = "管理口"
         @data_a  << w
       end
     end
     respond_to do |format|
       format.html
     end
   end 

   def edit
     @data_b = []
     # @eth_info = `sed -nr '/(lo:|Inter-|face)/!p' /proc/net/dev | awk -F":" '{print $1,$1}'`
     # @eth_arr_1 = @eth_info.split("\n")
     # @eth_arr_1.each do |f|
     #   @data_b  << f.split(" ")
     # end
     
     count = getNICnum
     #puts count.size
     if count == 7
       @data_b  << ["管理口", "eth6"]
     elsif count == 6 || count == 1
       @data_b  << ["管理口", "eth0"]
     else
       # @data_b  << ["eth2", "eth2"]
     end
   end

   def update
     count = getNICnum
     if count == 7
       upeth = "eth6"
     elsif count == 6 || count == 1
       upeth = "eth0"
     else
       #upeth = "eth2"
       raise "The number of NIC is wrong"
     end
     
     #upeth = params[:upeth]
     ip = params[:ip]
     msk = params[:msk]
     gw = params[:gw]
     mac = params[:mac]
     
     #puts "#{ip}  #{msk}  #{gw}  #{mac}"
     if upeth != nil && ip != nil && msk != nil && gw != nil && mac != nil
       exec=`#{Rails.root}/shell/ipabc.sh #{upeth} #{ip} #{msk} #{mac} #{gw}`
       `service network restart`
       DataObjects::Pooling.pools.each do |pool|
         pool.dispose
       end
       @log = Log.new
       time = Time.new
       @log[:optime] = time.strftime("%Y-%m-%d %H:%M:%S")
       @log[:ip]=request.remote_ip
       @log[:username]=@current_user
       @log[:opobject]="更改网络配置"
       @log[:opdetail]="更改网络成功"
       @log.save
     end
    
     #redirect_to network_path, :status => :moved_permanently
     redirect_to  :action => "show"
     
     #respond_to do |format|
       #format.html { redirect_to "http://localhost:3000" }
       #format.html
     #end
   end

   def getNIC
     nic_info = nil
     nic_name = params[:name]
     data = `#{Rails.root}/shell/changeip.sh`
     wangka = data.split("#")
     wangka.each do |wang|
       w = wang.split(",")
       if w[0] == nic_name
         nic_info = {:ip => w[1], :mask => w[2], :gw => w[3], :mac => w[4]}
         break
       end
     end
     
     respond_to do |format|
       format.json { render :json => nic_info }
     end
   end

   def getNICnum
     data = `sed -nr '/(lo:|Inter-|face)/!p' /proc/net/dev | awk -F":" '{print $1,$1}'`
     count = data.split("\n")
     return count.size
   end

   def self.getNICnum
     data = `sed -nr '/(lo:|Inter-|face)/!p' /proc/net/dev | awk -F":" '{print $1,$1}'`
     count = data.split("\n")
     return count.size
   end

   def self.getNICname
     count = NetworkController::getNICnum
     ethname = " ";
     if count == 7
       ethname = "eth6"
     elsif count == 6 || count == 1
       ethname = "eth0"
     end
     return ethname
   end
end
