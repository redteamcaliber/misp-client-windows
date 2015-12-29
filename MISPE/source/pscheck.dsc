EXTERNAL VDSIPP.DLL,APIKEY
#DEFINE COMMAND, INTERNET
#DEFINE FUNCTION, INTERNET

external string
#DEFINE FUNCTION,STRING

Title "Jigsaw Security HIDS Process Checking"

%%logfile = @path(%0)logs\@datetime(mm-dd-yyyy hhnnss)"-filemonitor.log"
list create,5
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Starting Process Protection Module"

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

file delete,@path(%0)badfiles.txt

  %%url = %%mispserverurl"/attributes/text/download/filename"
  INTERNET HTTP,CREATE,1
  INTERNET HTTP,HEADER,1,%%key
  INTERNET HTTP,THREADS,1,OFF
  INTERNET HTTP,PROTOCOL,1,1
  if @equal(%%proxy,1)
  INTERNET HTTP,PROXY,1,%%proxyserverurl,%%proxyport,%%proxyusername,%%proxypassword,%%proxyversion
  end
  INTERNET HTTP,USERAGENT,1,"Jigsaw Security HIDS Client Process Protection Module"
  list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Downloading Filename Threats from "%%mispserverurl
  INTERNET HTTP,DOWNLOAD,1,%%url,@path(%0)badprocs.txt
  INTERNET HTTP,DESTROY,1

timer START,1,CTDOWN,00-00:00:15
  
  
:Evloop
  wait event
  goto @event()


  
:timer1ctdown
timer stop,1  
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Checking for Malicious Files on Endpoint"
gosub writelogs
file delete,@path(%0)cache\procs.txt
wait 3
runh cmd.exe /C tasklist >> @path(%0)cache\procs.txt,wait
gosub checkfiles

timer START,1,CTDOWN,00-00:59:00
goto evloop

:writelogs
list savefile,5,%%logfile
exit

:checkfiles
INIFILE OPEN,@path(%0)settings\settings.ini
%%popupalert = @iniread(settings,popupalert)
INIFILE CLOSE
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Checking Processes for Threats"
list create,2
list loadfile,2,@path(%0)badprocs.txt
%%now = 0
%%total = @count(2)
REPEAT
%%ioc = @next(2)
if @string(FileOps, HoldsString,@path(%0)cache\procs.txt,,%%ioc,,,)
if @equal(%%ioc,cmd.exe)
goto nothreat
end
if @equal(%%ioc,setup.exe)
goto nothreat
end
if @equal(%%ioc,desktop.ini)
goto nothreat
end
if @equal(%%ioc,updater.exe)
goto nothreat
end
if @equal(%%ioc,wmpnetwk.exe)
goto nothreat
end
if @equal(%%ioc,wmiprvse.exe)
goto nothreat
end
if @equal(%%ioc,winlogon.exe)
goto nothreat
end
if @equal(%%ioc,svchost.exe)
goto nothreat
end
if @equal(%%ioc,svc.exe)
goto nothreat
end
if @equal(%%ioc,spoolsv.exe)
goto nothreat
end
if @equal(%%ioc,update.exe)
goto nothreat
end
if @equal(%%ioc,taskmgr.exe)
goto nothreat
end
if @equal(%%ioc,start.exe)
goto nothreat
end
if @equal(%%ioc,device.exe)
goto nothreat
end
if @equal(%%ioc,services.exe)
goto nothreat
end
if @equal(%%ioc,service.exe)
goto nothreat
end
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Possible Threatening Process Detected "%%ioc
inifile open,@path(%0)settings\threat.ini
inifile write,settings,threat,%%ioc
inifile write,settings,message,Possible Malicious Process Running %%ioc
list add,5,@datetime(dd-mmm-yyyy hh:nn:ss am/pm)": Consider submittimg to our sandbox for evaluation"
inifile close
list savefile,5,%%logfile
end
:nothreat
%%now = @succ(%%now)
UNTIL @equal(%%now,%%total)
list close,2

list savefile,5,%%logfile
timer START,1,CTDOWN,0-00:00:15
exit

