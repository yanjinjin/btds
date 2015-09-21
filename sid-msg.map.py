#/usr/bin/env python
# -*- coding=UTF-8 -*-
import sys
import string
import os
import time

SIDFILENAME="sid-msg.map"
VERSIONFILENAME="version"
CURRENTVERSION="1.0"
rule_num=0;

def msubstring(start_str, end_str, html):
    start = html.find(start_str)
    if start >= 0:
        start += len(start_str)
        end = html.find(end_str, start)
        if end >= 0:
            return html[start:end].strip()
			
def sid_file(in_filename,sid_out_file):
    global rule_num
    alert='alert '
    start_sid='sid:'
    end_sid=';'
    start_msg='msg:\"'
    end_msg='\";'
	
    file_object = open(in_filename,'r')
    
    try:
        list_of_all_the_lines = file_object.readlines()
        for line in list_of_all_the_lines:
			if 0==line.find(alert):
				sid=msubstring(start_sid,end_sid,line);
				msg=msubstring(start_msg,end_msg,line);
				sid_out_file.write(sid+" || "+msg+"\n");
			rule_num=rule_num+1
    finally:
        file_object.close()
		
def version_file(sid_out_file):
	 global rule_num
	 sid_out_file.write("version:"+CURRENTVERSION+"\n");
	 sid_out_file.write("date:"+time.strftime("%Y-%m-%d", time.localtime())+"\n");
	 sid_out_file.write("total:"+str(rule_num)+"\n");
	 
if __name__=='__main__':
	if os.path.exists(SIDFILENAME):
		os.remove(SIDFILENAME)
	sid_out_file=open(SIDFILENAME ,'a+')
	
	if os.path.exists(VERSIONFILENAME):
		os.remove(VERSIONFILENAME)
	version_out_file=open(VERSIONFILENAME ,'a+')
	
	sid_file("static.rules",sid_out_file)
	sid_file("feeds.rules",sid_out_file)
	sid_file("botcc.rules",sid_out_file)
	sid_file("activex.rules",sid_out_file)
	sid_file("attack_response.rules",sid_out_file)
	sid_file("botcc.portgrouped.rules",sid_out_file)
	sid_file("chat.rules",sid_out_file)
	sid_file("ciarmy.rules",sid_out_file)
	sid_file("compromised.rules",sid_out_file)
	sid_file("current_events.rules",sid_out_file)
	sid_file("deleted.rules",sid_out_file)
	sid_file("dns.rules",sid_out_file)
	sid_file("dos.rules",sid_out_file)
	sid_file("drop.rules",sid_out_file)
	sid_file("dshield.rules",sid_out_file)
	sid_file("exploit.rules",sid_out_file)
	sid_file("ftp.rules",sid_out_file)
	sid_file("games.rules",sid_out_file)
	sid_file("icmp_info.rules",sid_out_file)
	sid_file("icmp.rules",sid_out_file)
	sid_file("imap.rules",sid_out_file)
	sid_file("inappropriate.rules",sid_out_file)
	sid_file("info.rules",sid_out_file)
	sid_file("malware.rules",sid_out_file)
	sid_file("misc.rules",sid_out_file)
	sid_file("mobile_malware.rules",sid_out_file)
	sid_file("netbios.rules",sid_out_file)
	sid_file("p2p.rules",sid_out_file)
	sid_file("policy.rules",sid_out_file)
	sid_file("pop3.rules",sid_out_file)
	sid_file("rbn-malvertisers.rules",sid_out_file)
	sid_file("rbn.rules",sid_out_file)
	sid_file("rpc.rules",sid_out_file)
	sid_file("scada.rules",sid_out_file)
	sid_file("scada_special.rules",sid_out_file)
	sid_file("scan.rules",sid_out_file)
	sid_file("shellcode.rules",sid_out_file)
	sid_file("smtp.rules",sid_out_file)
	sid_file("snmp.rules",sid_out_file)
	sid_file("sql.rules",sid_out_file)
	sid_file("telnet.rules",sid_out_file)
	sid_file("tftp.rules",sid_out_file)
	sid_file("tor.rules",sid_out_file)
	sid_file("trojan.rules",sid_out_file)
	sid_file("user_agents.rules",sid_out_file)
	sid_file("voip.rules",sid_out_file)
	sid_file("web_client.rules",sid_out_file)
	sid_file("web_server.rules",sid_out_file)
	sid_file("web_specific_apps.rules",sid_out_file)
	sid_file("worm.rules",sid_out_file)
	version_file(version_out_file)
	sid_out_file.close()
	version_out_file.close();
