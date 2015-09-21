module Snorby
  module Jobs
    class SysStatusJob < Struct.new(:verbose)

      @@file = "#{Rails.root}/tmp/sys_status/status"
      @@path = "#{Rails.root}/tmp/sys_status"
      @@thread = "#{Rails.root}/tmp/sys_status/thread"

      def perform
        `echo "1" > #{@@thread}`
        i = 0
        while status? && i<= 1440
          if i==0 || i==360 || i==720 || i==1080 || i==1440
            killTcpdump
          end
          `echo "1" > #{@@thread}`
          cpu = cpustate(`bash shell/cpu.sh`)
          ram = ramstate(`bash shell/ram.sh`)
          disk = diskstate(`bash shell/disk.sh`)
          if !FileTest::exist?(@@file)
            `touch #{@@file}`
          end
          `echo "#{cpu} #{ram} #{disk}" > #{@@file}`
          i = i + 1
          #sleep 5
	end
        `echo "0" > #{@@thread}`
        if Snorby::Jobs.sys_status?
          Snorby::Jobs.sys_status.destroy!
          Delayed::Job.enqueue(Snorby::Jobs::SysStatusJob.new(false), 
            :priority => 10, :run_at => DateTime.now)
        end
      end

      def killTcpdump
        count = `ps -ef|grep tcpdump|grep -v grep|wc -l`.split("\n")[0].to_i
        if count > 100
          killTcpByTimeOrder(count-100)
        else
          killTcpByTimeOrder(0)
        end
      end

      def killTcpByTimeOrder(amount=0)
        str = `ps -eo pid,etime,cmd|grep tcpdump|awk '{print $1"|"$2}'`.split("\n")
        if amount == 0 #kill the tcpdumps which etime more than 24hours
          str.each do |l|
            line = l.split("|")
            if (line[1]=~/\d{1,2}-\d{2}/) != nil
              #puts "kill #{line[0]}"
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
              #puts "kill #{pid}"
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

      def self.thread_status? # true means running
        if !File.directory?(@@path)
          `mkdir #{@@path}`
        end
        if FileTest::exist?(@@thread)
          file = File.open(@@thread)
          status = file.read.to_i
          file.close
          if status ==1
            return true
          else
            return false
          end
        else
          `touch #{@@thread}`
          return false
        end
      end

      def status? #only use in Worker
        if !File.directory?(@@path)
          `mkdir #{@@path}`
        end
        if FileTest::exist?(@@thread)
          file = File.open(@@thread)
          status = file.read.to_i
          file.close
          if status ==1
            return true
          else
            return false
          end
        else
          `touch #{@@thread}`
          return false
        end
      end
      
      def self.thread
        @@thread
      end
      
      def cpustate(str)
        return str
      end

      def ramstate(str)
        return str
      end

      def diskstate(str)
        return str
      end
    end
  end
end
