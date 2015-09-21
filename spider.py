#/usr/bin/env python
# -*- coding=UTF-8 -*-
import urllib
import re
import os
import string
import socket

RULEID=3000000
RULEFILE="feeds.rules"

####################base class ##################
class spider(object):
	count=0
	def isFilter(self,rule):
		self.count+=1
		if len(rule)<8:
		    return 1
		return 0
		
	def setRules(self,rules,msg,type):
		global RULEID 
		i=0
		write_file=open(RULEFILE,'a+')
		try:
			for rule in rules:
				if self.isFilter(rule)==1:
				    continue
				RULEID+=1
				write_file.write("alert ip $HOME_NET any -> ["+rule+"] any (msg:\""+msg+"\"; threshold: type limit, track by_src, seconds 60, count 1; classtype:"+type+"; sid:"+str(RULEID)+";rev:1; )\n")
		finally:
			write_file.close()
		
	def getRules(self,html):
		regex = re.compile(r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b', re.IGNORECASE)
		rules = re.findall(regex, html)
		return rules

	def getHtml(self,url):
		try:
			page = urllib.urlopen(url)
			html = page.read()
			return html
		except:
			print "connect failed"+url 
			return None
		
	def __init__(self,url,msg,type):
		html = self.getHtml(url)
		if html==None:
			return
		rules=self.getRules(html)
		self.setRules(rules,msg,type)
		
####################malware-ip spider ##################		
class malwareIpSpider(spider):
	def __init__(self,url,msg,type):
		spider.__init__(self,url,msg,type)
		
####################malware-domain spider ##################		
class malwareDomainSpider(spider):
	#重载方法
	def isFilter(self,rule):
		self.count+=1
		if self.count<=6 or len(rule)<8:
		    return 1
		return 0
		
	def setRules(self,rules,msg,type):
		global RULEID 
		write_file=open(RULEFILE,'a+')
		try:
			for rule in rules:
				if self.isFilter(rule)==1:
				   continue
				RULEID+=1
				write_file.write("alert udp $HOME_NET any -> $EXTERNAL_NET 53 (msg:\""+msg+"\"; content:\""+rule+"\";nocase; threshold: type limit, track by_src, seconds 60, count 1;classtype:"+type+"; sid:"+str(RULEID)+"; rev:1;)\n")
		finally:
			write_file.close()
	def getRules(self,html):
		html=html.replace('.','|03|')
		return html.split("\n")

	def __init__(self,url,msg,type):
		spider.__init__(self,url,msg,type)
		
####################Malc0de spider ##################
class malcodeSpider(malwareIpSpider):
	def __init__(self,url,msg,type):
		malwareIpSpider.__init__(self,url,msg,type)

####################Feodo spider ##################
class feodoSpider(malwareDomainSpider):
	def isFilter(self,rule):
		self.count+=1
		if self.count<=7 or len(rule)<8:
		    return 1
		if rule.find("# END")>=0:
			return 1
		return 0
		
	def __init__(self,url,msg,type):
		malwareDomainSpider.__init__(self,url,msg,type)
		
####################Palevo spider ##################
class palevoSpider(malwareDomainSpider):
	def isFilter(self,rule):
		self.count+=1
		if self.count<=2 or len(rule)<8:
		    return 1
		return 0
	def __init__(self,url,msg,type):
		malwareDomainSpider.__init__(self,url,msg,type)

####################malwareDomainlist spider ##################
class malwareDomainlistSpider(malwareDomainSpider):
	def getRules(self,html):
		html=html.replace("127.0.0.1  ","")
		html=html.replace('\r','')
		html=html.replace('.','|03|')
		return html.split("\n")
		
	def isFilter(self,rule):
		self.count+=1
		if self.count<=6 or len(rule)<8:
		    return 1
		return 0
	def __init__(self,url,msg,type):
		malwareDomainSpider.__init__(self,url,msg,type)

######################cybercrime spider#####################
class cybercrimeSpider(malwareDomainSpider):
	def setRules(self,rules,msg,type):
		global RULEID 
		write_file=open(RULEFILE,'a+')
		try:
			for rule in rules:
				RULEID+=1
				url=rule.split("/" , 1)
				if len(url)==2:
					write_file.write("alert tcp $HOME_NET any -> $EXTERNAL_NET 80 (msg:\""+msg+"\"; content:\"GET /"+url[1]+"\";nocase; content:\"HOST: "+url[0]+"\";nocase; threshold: type limit, track by_src, seconds 60, count 1;classtype:"+type+"; sid:"+str(RULEID)+"; rev:1;)\n")
				elif len(url)==1:
					write_file.write("alert tcp $HOME_NET any -> $EXTERNAL_NET 80 (msg:\""+msg+"\"; content:\"GET /\";nocase; content:\"HOST: "+url[0]+"\";nocase; threshold: type limit, track by_src, seconds 60, count 1;classtype:"+type+"; sid:"+str(RULEID)+"; rev:1;)\n")
				else:
					continue
		finally:
			write_file.close()		
	def getRules(self,html):
		html=html.replace('.','|2e|')
        	html=html.replace(';','|3b|')
		return html.split("<br />")
		
	def __init__(self,url,msg,type):
		malwareDomainSpider.__init__(self,url,msg,type)
		
if __name__=='__main__':
	if os.path.exists(RULEFILE):
		os.remove(RULEFILE)
	
	socket.setdefaulttimeout(20)
	 
	malwareIpSpider("http://www.autoshun.org/files/shunlist.csv","恶意ip地址Autoshun","malware-ip")
	
	malwareIpSpider("http://www.openbl.org/lists/base_7days.txt","恶意ip地址OpenBL","malware-ip")
	#must continue write
	#malcodeSpider("http://malc0de.com/bl/IP_Blacklist.txt","恶意ip地址Malc0de","malware-ip")

	malwareIpSpider("http://www.malwaredomainlist.com/hostslist/ip.txt","恶意ip地址","malware-ip")
	malwareDomainlistSpider("http://www.malwaredomainlist.com/hostslist/hosts.txt","恶意域名","malware-domain")
	
	malwareIpSpider("https://feodotracker.abuse.ch/blocklist/?download=ipblocklist","Feodo木马","trojan-activity")
	feodoSpider("https://feodotracker.abuse.ch/blocklist/?download=domainblocklist","Feodo木马","trojan-activity")
	
	malwareIpSpider("https://palevotracker.abuse.ch/blocklists.php?download=ipblocklist","Palevo","botnet-activity")
	palevoSpider("https://palevotracker.abuse.ch/blocklists.php?download=domainblocklist","Palevo","botnet-activity")
	
	malwareIpSpider("https://zeustracker.abuse.ch/blocklist.php?download=ipblocklist","Zeus","botnet-activity")
	malwareDomainSpider("https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist","Zeus","botnet-activity")
	
	malwareIpSpider("http://danger.rulez.sk/projects/bruteforceblocker/blist.php","恶意ip地址VX vault","malware-ip")
	
	cybercrimeSpider("http://cybercrime-tracker.net/all.php","cybercrime-tracker","malware-domain")
