class Rule

  include DataMapper::Resource

  property :id, Serial, :required => true, :unique => true , :index => true

  #property :type1, String, :length => 10
  #property :type2, String, :length => 6
  #property :source, Text
  #property :sourcep, Text
  #property :to, String, :length => 2
  #property :target, Text
  #property :targetp, Text
  property :msg, Text
  property :classtype, String
  #property :sid, Integer , :required => true, :unique => true , :index => true
  @@logpath = "#{Rails.root}/log"
  @@putout = "/analysis_error.log"
  @@suricata_path = "/etc/suricata/rules"
  @@log = "/rules.log"
  attr_accessor:flag

  def self.input(path = Rule.suricata_path)
    if path.class == Array
      path = path[0].to_s
    end
    if path.size == 0
      path = Rule.suricata_path
    end
    count = 0
    #log file init
    self.loginit
    self.logit("==start== at #{Time.now.to_s}")
    p = path
    if File.directory? p
      self.backup
      self.delete_all
      Dir.foreach(p) do |file|
	if file.end_with?('.rules')
	  #puts p+file
	  count = self.savefiletodb(p+'/'+file, count, file)
	end
      end
    else
      #throw no such folder exception
      raise "no such folder"
    end
    self.logit("|total num| : #{count}
--end-- at #{Time.now.to_s}")
    return count
  end

  def self.savefiletodb(filepath, count, filename)
     text = File.open(filepath)
     text.each_line do |line|
       if(!line.start_with?("#","\t","\n","\r"))
         count = count + 1
	 rule = Rule.new.analysis(line.strip, filename)
         #something wroing here,but I dont know why,
         #I have to create a new Rule,then the saveing can run correct
	 begin
	   @rule = Rule.new
	   @rule.msg = rule.msg
	   @rule.id = rule.id
	   @rule.classtype = rule.classtype
	   #puts @rule.id
	   if(@rule.id != nil && @rule.id != "")
	     @rule.save
	   end#e if
	   puts @rule.errors.full_messages
	 rescue => e
	   puts e
	 end#e bgein
       end#e if
     end#e do
     text.close
     return count
  end

  def analysis(s, filename)
    @flag = false
    i = 0
    while(i<=s.length)
      if(s[i]=="(")
        s1 = s[0,i-1]
        s2 = s[i+1..-2]
        break
      end
      i = i + 1
    end
    #analysisOne(s1)
    analysisByRegex(s2)
    #s3 = analysisTwo(s2)
    if @flag
      p = @@logpath+@@putout
      file = File.new(p,"a")
      #file.puts "<font size='2' color=black>"+filename+"</br>"+s1+"("+s3+")</font></br></br>"
      file.puts filename+s1+"("+s2+")"
      file.close
    end
    return self
  end
=begin
  def analysisOne(s)
    list1 = s.split(" ")
    @type1 = list1[0].strip()
    @type2 = list1[1].strip()
    @source = list1[2].strip().gsub(/[\[|\]]/,"")
    @sourcep = list1[3].strip().gsub(/[\[|\]]/,"")
    @to = list1[4].strip()
    @target = list1[5].strip().gsub(/[\[|\]]/,"")
    @targetp = list1[6].strip().gsub(/[\[|\]]/,"")
  end
=end
  def analysisByRegex(s)
    # get msg
    begin
      @msg = s.match(/msg:".*?";/)[0][5..-3]
    rescue => e
      @flag = ture
      puts "something wrong in msg" + e.to_s
    end
    #get classtype and there is no classtype in some rules
    begin
      @classtype = s.match(/classtype:.*?;/)[0][10..-2]
    rescue => e
      puts "something wrong in classtype" + e.to_s
    end
    #get sid
    begin
      @id = s.match(/sid:[\d]{1,};/)[0][4..-2].strip.to_i
    rescue => e
      @flag = true
      puts "something wrong in sid" + e.to_s
    end
    if @flag
      puts @id
    end
  end
=begin
  def analysisTwo(s)
    flag = false
    j = 0
    p = 0
    temp = ""
    info = ""
    key = ""
    infos = Array.new
    while(j<s.length)
      current = s[j]
      #find the key word
      if(current != ":" && current != " ")
        temp = temp + s[j]
	case temp
	when "app-layer-event", "asn1", "ack", "byte_jump", "byte_extract", "byte_test", 
             "content", "classtype", "decode-event", "distance", "depth", "dsize", "detection_filter", "ftpbounce",
             "fileext", "flowint", "flow", "flags", "flowbits", "file_data", "fast_pattern", " ftpbounce",
             "http_header", "http_uri", "http_user_agent", "http_raw_header","http_method", 
             "http_stat_code", "http_stat_msg", "http_client_body", "http_cookie", "http_raw_uri",
             "ipv4-csum", "icmpv4-csum", "icmpv6-csum", "isdataat", "ip_proto", "icode", "itype", "icmp_id", "id", "msg",
             "nocase", "noalert", "offset", "pcre", "rawbytes", "tcpv4-csum", "tcpv6-csum", "tag", "tls.fingerprint",
             "threshold", "rev", "reference", "sid", "stream-event", "ssl_version", "ssl_state", "ssh.softwareversion", "seq",
             "uricontent", "udpv6-csum", "udpv4-csum", "urilen", "within", "window"
          #set pointer to the beginnig of info
	  p = j
	  key = temp
	else
          
	end#end case
      end#e if
      if(current == ";" && key != "")#for now, signal will never be nil
        info = s[p+1..j-1].strip
        #puts info
	if(info.start_with?(":"))
	  info = info[1..-1]
	end
        if(info.scan(/;/).length > 0)
          @flag = true
          infos.push(info)
        end
	case key
        when "msg"
	  @msg = info
	when "sid"
	  #@sid = info.to_i
	  @id = info.to_i
 	when "classtype"
	  @classtype = info
	#when "reference"
	  #if(@reference == nil|| @reference == "")
	    #@reference = info
	  #else
	    #@reference = @reference + "\s" + info
	  #end
        else

	end#e case
	#key = ""
	temp = ""
      end#e if
        j = j + 1
    end#e while
    last = nil
    infos.each do |inf|
      if last==nil
         s.gsub!(inf,"<font color=red>"+inf+"</font>")
      elsif inf.index(last) != nil
         s.gsub!("<font color=red>"+last+"</font>",last)
         s.gsub!(inf,"<font color=red>"+inf+"</font>")
      end#e if
      last = inf
    end#e do
    return s
  end#e analysistwo
=end
  def self.recover_from_backup
    sql = "drop table if exists rules;"
    db_execute(sql)
    sql = "create table rules select * from rules_backup;"
    db_execute(sql)
    self.logit("recover from rules_backup at #{Time.now.to_s}")
  end

  def self.loginit
    if !File.directory? @@logpath
      `mkdir #{@@logpath}`
    end
    if !FileTest.exist? @@logpath+@@log
      `touch #{@@logpath}#{@@log}`
    end
     if !FileTest.exist? @@logpath+@@putout
      `touch #{@@logpath}#{@@putout}`
    end
    file = File.new("#{@@logpath}#{@@putout}","w")
    file.close
  end

  def self.logit(str)
    file = File.new("#{@@logpath}#{@@log}","a")
    file.puts str
    file.close
  end

  def self.backup
    sql = "drop table if exists rules_backup;"
    db_execute(sql)
    sql = "create table rules_backup select * from rules;"
    db_execute(sql)
    self.logit("back up table rules at #{Time.now.to_s}")
  end

  def self.delete_all
    sql = "delete from rules where 1=1 ; "
    db_execute(sql)
  end

  def self.path
    return @@path
  end

  def self.suricata_path
    return @@suricata_path
  end

  def self.putout
    return @@putout
  end

end
