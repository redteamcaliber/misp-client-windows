EXTERNAL VDSIPP.DLL,APIKEY
#DEFINE COMMAND, INTERNET
#DEFINE FUNCTION, INTERNET

external string
#DEFINE FUNCTION,STRING

TITLE "Jigsaw HIDS Netwatch Protection"

%%logfile = @path(%0)logs\@datetime(mm-dd-yyyy hhnnss)"-netthreats.log"
list create,5
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Starting Network Protection Module"

INIFILE OPEN,@path(%0)settings\settings.ini
%%version = @iniread(settings,version)
%%key = @iniread(settings,key)
%%hostname = @iniread(settings,hostname)
%%syslogserver = @iniread(settings,syslogserver)
%%mispserverurl = @iniread(settings,mispserverurl)
%%popupalert = @iniread(settings,popupalert)
%%proxy = @iniread(settings,proxy)
%%proxyport = @iniread(settings,proxyport)
%%proxyusername = @iniread(settings,proxyusername)
%%proxypassword = @iniread(settings,proxypassword)
%%proxyversion = @iniread(settings,proxyversion)
INIFILE CLOSE


# DOWNLOAD IPS INDICATORS #

  file delete,@path(%0)ipsrc.txt
  file delete,@path(%0)ipdst.txt
  file delete,@path(%0)domain.txt
  

  %%url = %%mispserverurl"/attributes/text/download/ip-src"
  INTERNET HTTP,CREATE,1
  INTERNET HTTP,HEADER,1,%%key
  INTERNET HTTP,THREADS,1,OFF
  INTERNET HTTP,PROTOCOL,1,1
  if @equal(%%proxy,1)
  INTERNET HTTP,PROXY,1,%%proxyserverurl,%%proxyport,%%proxyusername,%%proxypassword,%%proxyversion
  end
  INTERNET HTTP,USERAGENT,1,"Jigsaw Security HIDS Client Network Module"
  list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Downloading IP Source Threats from "%%mispserverurl
  INTERNET HTTP,DOWNLOAD,1,%%url,@path(%0)ipsrc.txt
  INTERNET HTTP,DESTROY,1
  
  %%url = %%mispserverurl"/attributes/text/download/ip-dst"
  INTERNET HTTP,CREATE,1
  INTERNET HTTP,HEADER,1,%%key
  INTERNET HTTP,THREADS,1,OFF
  INTERNET HTTP,PROTOCOL,1,1
  if @equal(%%proxy,1)
  INTERNET HTTP,PROXY,1,%%proxyserverurl,%%proxyport,%%proxyusername,%%proxypassword,%%proxyversion
  end
  INTERNET HTTP,USERAGENT,1,"Jigsaw Security HIDS Client Network Module"
  list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Downloading IP Destination Threats from "%%mispserverurl
  INTERNET HTTP,DOWNLOAD,1,%%url,@path(%0)ipdst.txt
  INTERNET HTTP,DESTROY,1

  %%url = %%mispserverurl"/attributes/text/download/domain"
  INTERNET HTTP,CREATE,1
  INTERNET HTTP,HEADER,1,%%key
  INTERNET HTTP,THREADS,1,OFF
  INTERNET HTTP,PROTOCOL,1,1
  if @equal(%%proxy,1)
  INTERNET HTTP,PROXY,1,%%proxyserverurl,%%proxyport,%%proxyusername,%%proxypassword,%%proxyversion
  end
  INTERNET HTTP,USERAGENT,1,"Jigsaw Security HIDS Client Network Module"
  list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Downloading Domain Threats from "%%mispserverurl
  INTERNET HTTP,DOWNLOAD,1,%%url,@path(%0)domain.txt
  INTERNET HTTP,DESTROY,1

timer START,1,CTDOWN,00-00:00:05

:Evloop
  wait event
  goto @event()





:timer1ctdown
  wait 0.5
  timer stop,1
  list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Checking network sockets"
  gosub writelogs
  file delete,@path(%0)cache\net.txt
  runh cmd.exe /C netstat.exe -an > @path(%0)cache\net.txt,wait
  runh cmd.exe /C netstat.exe -af >> @path(%0)cache\net.txt,wait
  gosub checkiocs
  goto evloop


  
:checkiocs
INIFILE OPEN,@path(%0)settings\settings.ini
%%popupalert = @iniread(settings,popupalert)
INIFILE CLOSE
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Checking Network for Threats"
list create,2
list loadfile,2,@path(%0)ipsrc.txt
%%now = 0
%%total = @count(2)
REPEAT
%%ioc = @next(2)
if @string(FileOps, HoldsString,@path(%0)cache\net.txt,,%%ioc,,,)
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Threat Detected HOST:"%%hostname" sent traffic to "%%ioc" known bad IOC"
inifile open,@path(%0)settings\threat.ini
inifile write,settings,threat,%%ioc
inifile write,settings,message,Threat communicated to Malicious location %%ioc
inifile close
list savefile,5,%%logfile
INIFILE OPEN,@path(%0)settings\settings.ini
%%popupalert = @iniread(settings,popupalert)
INIFILE CLOSE
if @equal(%%popupalert,1)
info "A threat has been detected by the Jigsaw Security Host Intrusion Detection System. This computer "%%hostname" attempted to connect to a known bad location "%%ioc" which is considered malicious. Please visit "%%mispserverurl" for additional information concerning this threat or call your IT support personnel and provide this information so they can determine what threat exist on the network."@cr()@cr()"Jigsaw Security Host Intrusion Version "%%version"."
end
end
%%now = @succ(%%now)
UNTIL @equal(%%now,%%total)
list close,2

list create,2
list loadfile,2,@path(%0)ipdst.txt
%%now = 0
%%total = @count(2)
REPEAT
%%ioc = @next(2)
if @string(FileOps, HoldsString,@path(%0)cache\net.txt,,%%ioc,,,)
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Threat Detected HOST:"%%hostname" sent traffic to "%%ioc
inifile open,@path(%0)settings\threat.ini
inifile write,settings,threat,%%ioc
inifile write,settings,message,Threat communicated to Malicious location %%ioc
inifile close
list savefile,5,%%logfile
if @equal(%%popupalert,1)
info "A threat has been detected by the Jigsaw Security Host Intrusion Detection System. This computer "%%hostname" attempted to connect to a known bad location "%%ioc" which is considered malicious. Please visit "%%mispserverurl" for additional information concerning this threat or call your IT support personnel and provide this information so they can determine what threat exist on the network."@cr()@cr()"Jigsaw Security Host Intrusion Version "%%version"."
end
end
%%now = @succ(%%now)
UNTIL @equal(%%now,%%total)
list close,2

list create,2
list loadfile,2,@path(%0)domain.txt
%%now = 0
%%total = @count(2)
REPEAT
%%ioc = @next(2)
if @string(FileOps, HoldsString,@path(%0)cache\net.txt,,%%ioc,,,)
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Threat Detected HOST:"%%hostname" sent traffic to "%%ioc
inifile open,@path(%0)settings\threat.ini
inifile write,settings,threat,%%ioc
inifile write,settings,message,Threat communicated to Malicious location %%ioc
inifile close
list savefile,5,%%logfile
if @equal(%%popupalert,1)
info "A threat has been detected by the Jigsaw Security Host Intrusion Detection System. This computer "%%hostname" attempted to connect to a known bad location "%%ioc" which is considered malicious. Please visit "%%mispserverurl" for additional information concerning this threat or call your IT support personnel and provide this information so they can determine what threat exist on the network."@cr()@cr()"Jigsaw Security Host Intrusion Version "%%version"."
end
end
%%now = @succ(%%now)
UNTIL @equal(%%now,%%total)
list close,2

list savefile,5,%%logfile
timer START,1,CTDOWN,0-00:00:15
exit

:writelogs
list savefile,5,%%logfile
exit

