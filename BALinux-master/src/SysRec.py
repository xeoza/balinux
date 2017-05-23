#!/usr/bin/python3

nUpdatesPerMinute = 10
dTime = 60 / nUpdatesPerMinute

import subprocess as sp
import re

path = "/tmp/history/"
#_________________________________
#Added system information for centre page
#files = open('/var/www/index.html','w')
#s=
#_________________________________
try:
    main = open('/tmp/history/main.txt', 'r')
    for i in main:
        j = i
    num = list(j.split())
    num = int(num[0])+1
    main.close()
except Exception:
    i = sp.check_output(["mkdir","-p","/tmp/history"])
    i = sp.check_output(["touch", "/tmp/history/main.txt"])
    num = 0

date = sp.check_output(["date", "+'%D %T'"], universal_newlines=True)
main = open('/tmp/history/main.txt','a')
main.write (str(num)+' '+date)
main.close()


files = []
fSuc = 0
oldData = False
prevNum = num - nUpdatesPerMinute + 1
for i in range (prevNum,num):
    pathF = path + str(i)
    try:
        files.append(open(pathF,'r'))
        fSuc += 1
    except Exception:
        pass

for i in range(fSuc):
    j = files[i].readline()

path = path + str(num)
current = open(path,'w')
current.write(date)

loadavg = sp.check_output(["cat", "/proc/loadavg"], universal_newlines=True)
loadavg = re.findall(r'\d\.\d{2}',loadavg)
#
#loadavg [x.xx, x.xx, x.xx]
#

disk = []
k = 0
for i in range (10):
    s = "/tmp/iostat/"+str(i)
    try:
        j = sp.check_output(["cat", s],universal_newlines=True)
        for n in range(2):
            for l in range(len(j)-6):
                if j[l:(l+7)] == 'Device:':
                    j = j[(l+7):]
                    break
        j = re.findall(r'(sda\d*)|(\d+,\d{2})',j)
        l = []
        for n in range(len(j)):
            if j[n][0] != '':
                l.append([j[n][0]])
            else:
                l[len(l)-1].append(j[n][1])
        j = []
        for n in l:
            if len(n) == 14:
                j.append(n)
        disk.append(j)
    except Exception:
        pass
#disk[numberOfCheck][numberOfDisk][name,13characters]
for i in range(len(disk[0])):
    currentDisk = disk[0][i][0]
    numOfHit = 1
    for j in range(1,len(disk)):
        for k in range(len(disk[j])):
            if (disk[j][k][0] == currentDisk):
                numOfHit += 1
                for l in range(1,14):
                    disk[0][i][l] = re.sub(',','.',disk[0][i][l])
                    disk[j][k][l] = re.sub(',','.',disk[j][k][l])
                    disk[0][i][l] = str(float(disk[j][k][l])+float(disk[0][i][l]))
    for i in range(len(disk[0])):
        for j in range(1,len(disk[0][i])):
            disk[0][i][j] = float(disk[0][i][j]) / numOfHit
            disk[0][i][j] = str("%.2f" % disk[0][i][j])
disk = disk[0]
#
#disk [[nameOfDisk,rrqm/s,wrqm/s,r/s,w/s,rkB/s,wkB/s,avgrq-sz,avgqu-sz,await,r_await,w_await,svctm,%util]],[disk2,...],...]
#



net = sp.check_output(["cat", "/proc/net/dev"], universal_newlines=True)
net = re.findall(r'(\w+:)|(\d+)',net)
j = len(net)
k = j
for i in range(j):
    if net[i][0]!='':
        net.append([net[i][0]])
        j += 1
    else:
        net[j-1].append(net[i][1])
for i in range (k):
    del net[0]
current.write(str(net)+'\n')
netPast = []
for i in range(fSuc):
    j = files[i].readline()
    netPast = j if (i == 0) else netPast
netPast = eval(netPast) if netPast != [] else netPast

for i in range(len(net)):
    for j in range(len(netPast)):
        if net[i][0] == netPast[j][0]:
            for k in range(1,len(net[i])):
                net[i][k] = str(int(net[i][k])-int(netPast[j][k]))
#net [[nameOfInterface, RECIEVED packets, packets, errs, drop, fifo, frame, compressed, multicast, TRANSMITTED packets errs,drop,fif$


netstat = sp.check_output(["netstat"], universal_newlines=True)
netstat = re.findall(r'(tcp.+)|(udp.+)',netstat)
closed = 0
listen = 0
syn_sent = 0
syn_received = 0
established = 0
close_wait = 0
fin_wait_1 = 0
close_wait = 0
fin_wait = 0
closing = 0
last_ack = 0
fin_wait_2 = 0
time_wait = 0
for i in range (len(netstat)):
    netstat[i] = netstat[i][0] if netstat[i][0] != '' else netstat [i][1]
    netstat[i] = re.sub(r'\s+', ' ', netstat[i])
    netstat[i] = list(netstat[i].split())
    if netstat[i][0] == 'tcp':
        if netstat[i][5] == 'CLOSED':
            closed += 1
        elif (netstat[i][5] == 'LISTEN') or (netstat[i][5] == 'LISTENING'):
            listen += 1
        elif netstat[i][5] == 'SYN_SENT':
            syn_sent += 1
        elif netstat[i][5] == 'SYN_RECEIVED':
            syn_received += 1
        elif netstat[i][5] == 'ESTABLISHED':
            established += 1
        elif netstat[i][5] == 'CLOSE_WAIT':
            close_wait += 1
        elif netstat[i][5] == 'FIN_WAIT_1':
            fin_wait_1 += 1
        elif netstat[i][5] == 'CLOSING':
            closing += 1
        elif netstat[i][5] == 'LAST_ACK':
            last_ack += 1
        elif netstat[i][5] == 'FIN_WAIT_2':
            fin_wait_2 += 1
        elif netstat[i][5] == 'TIME_WAIT':
            time_wait += 1
current.write(str(closed)+' '+str(listen)+' '+str(syn_sent)+' '+str(syn_received)+' '+str(established)+' '+str(close_wait)+' '+str(fin_wait)+' '+str(closing)+' '+str(last_ack)+' '+str(fin_wait_2)+' '+str(time_wait)+'\n')
l=[0]
l = l * 11
for i in range(fSuc):
    j = files[i].readline()
    j = list(j.split())
    closed += int(j[0])
    listen += int(j[1])
    syn_sent += int(j[2])
    syn_received += int(j[3])
    established += int(j[4])
    close_wait += int(j[5])
    fin_wait_1 += int(j[6])
    closing += int(j[7])
    last_ack += int(j[8])
    fin_wait_2 += int(j[9])
    time_wait += int(j[10])

closed /= (fSuc+1)
listen /= (fSuc+1)
syn_sent /= (fSuc+1)
syn_received /= (fSuc+1)
established /= (fSuc+1)
close_wait /= int(fSuc+1)
fin_wait_1 /= int(fSuc+1)
closing /= int(fSuc+1)
last_ack /= int(fSuc+1)
fin_wait_2 /= int(fSuc+1)
time_wait /= int(fSuc+1)

closed = str("%.2f" % closed)
listen = str("%.2f" % listen)
syn_sent = str("%.2f" % syn_sent)
syn_received = str("%.2f" % syn_received)
established = str("%.2f" % established)
close_wait = str("%.2f" % close_wait)
fin_wait_1 = str("%.2f" % fin_wait_1)
closing = str("%.2f" % closing)
last_ack = str("%.2f" % last_ack)
fin_wait_2 = str("%.2f" % fin_wait_2)
time_wait = str("%.2f" % time_wait)

#netstat [[Proto Recv-Q Send-Q Local Address Foreign Address Stat],[...],...]


#cpu = sp.check_output(["mpstat"],universal_newlines=True)
#cpu = re.findall(r'\d+,\d{2}',cpu)
#for i in range(4):
#    cpu[i] = re.sub(',','.',cpu[i])
#cpu[9] = re.sub(',','.',cpu[9])
#cpu[0] = float(cpu[0])+float(cpu[1])
#cpu[1] = cpu[2]
#cpu[2] = cpu[9]
#for i in range (6):
#    del cpu[4]
#cpu[0] = str("%.2f" % cpu[0])
#cpu [usr+nice,sys,idle,io]
#current.write(str(cpu)+'\n')

#for i in range(len(cpu)):
#    cpu[i]=float(cpu[i])
#for i in range(fSuc):
#    j = files[i].readline()
#    j = eval(j)
#    for k in range(len(j)):
#        cpu[k] += float(j[k])
#for i in range(len(cpu)):
#    cpu[i] /= (fSuc + 1)
#    cpu[i] = str("%.2f" % cpu[i])


tcpdump = ""
for i in range (10):
    s = "/tmp/tcpdump/"+str(i)
    try:
        tcpdump += sp.check_output(["cat", s],universal_newlines=True)
    except Exception:
        pass
tcpdump = re.findall(r'(length\s\d+):.+(proto\s\w+).+\n\D+(\d+\.\d+\.\d+\.\d+\.\d+)\D+(\d+\.\d+\.\d+\.\d+\.\d+)',tcpdump)
for i in range(len(tcpdump)):
    tcpdump[i] = list(tcpdump[i])
    tcpdump[i][0] = tcpdump[i][0][7:]
    tcpdump[i][1] = tcpdump[i][1][6:]
#[[length,proto,ipsrc,ipdst],[...],...]


tcp = 0
udp = 0
icmp = 0
for i in range(len(tcpdump)):
    if tcpdump[i][1] == 'TCP':
        tcp += int(tcpdump[i][0])
    elif tcpdump[i][1] == 'UDP':
        udp += int(tcpdump[i][0])
    elif tcpdump[i][1] == 'ICMP':
        icmp += int(tcpdump[i][0])
    tcpdump[i][2] = [tcpdump[i][2],tcpdump[i][3]]
    tcpdump[i][3] = tcpdump[i][0]
    tcpdump[i][2].sort()
    del tcpdump[i][0]
    j = tcpdump[i][1]
    tcpdump[i][1] = tcpdump[i][0]
    tcpdump[i][0] = j
    tcpdump[i][2] = int(tcpdump[i][2])
tcpdump.sort()
i = 0
while(i<len(tcpdump)):
    if tcpdump[i][1]=='UDP':
        del tcpdump[i]
    else:
        tcpdump[i][1] = 1
        i += 1
i = 1

while (i<len(tcpdump)):
    if (tcpdump[i-1][0]==tcpdump[i][0]):
        tcpdump[i][2] += tcpdump[i-1][2]
        tcpdump[i][1] += tcpdump[i-1][1]
        del tcpdump[i-1]
    else:
        i += 1


diskSpace = sp.check_output(["df", "-h"],universal_newlines=True)
diskInodes = sp.check_output(["df", "-i"],universal_newlines=True)
diskSpace = re.findall(r'(\S+)\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\/\S*)',diskSpace)
diskInodes = re.findall(r'(\S+)\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\/\S*)',diskInodes)
i = 0
while (i < len(diskSpace)):
    diskSpace[i]=list(diskSpace[i])
    diskSpace[i].append(diskInodes[i][1])
    if ((re.search(r'/sys',diskSpace[i][2])!=None) or (re.search(r'/proc',diskSpace[i][2])!=None) or (re.search(r'/dev',diskSpace[i][2])!=None)):
        del diskSpace[i]
        del diskInodes[i]
    else:
        i += 1
for i in range(len(diskSpace)):
    j = diskSpace[i][1]
    diskSpace[i][1] = diskSpace[i][2]
    diskSpace[i][2] = j
#diskSpace[[fileSystem,Mount,FreeSpace,FreeInodes],[]...]
for i in range(len(diskSpace)):
    diskSpace[i][3] = int(diskSpace[i][3][:len(diskSpace[i][3])-1])
    re.sub(',','.',diskSpace[i][2])
    diskSpace[i][2] = int(diskSpace[i][2][:len(diskSpace[i][2])-1])
current.write(str(diskSpace)+'\n')

m = []
for i in range(fSuc):
    j = files[i].readline()
    j = eval(j)
    m.append(j)

for i in range(len(diskSpace)):
    numOfHit = 1
    for j in range(len(m)):
        for k in range(len(m[j])):
            if m[j][k][1]==diskSpace[i][1]:
                diskSpace[i][2] += m[j][k][2]
                diskSpace[i][3] += m[j][k][3]
                numOfHit+=1
    diskSpace[i][2] /= numOfHit
    diskSpace[i][3] /= numOfHit

current.write('#\n')
current.write(str(loadavg)+'\n')
current.write(str(disk)+'\n')
current.write(str(tcpdump)+'\n')
current.write(str(netstat)+'\n')
current.write(closed+' '+listen+' '+syn_sent+' '+syn_received+' '+established+' '+close_wait+' '+fin_wait_1+' '+closing+' '+last_ack+' '+fin_wait_2+' '+time_wait+'\n')
#current.write(str(cpu)+'\n')
current.write(str(diskSpace)+'\n')
current.close()


#if (oldData and fSuc == 10):
#    i = oldDate
#    while True:
#        j = files[0].readline()
#        if j == '':
#            break;
#        else:
#            i += j

for j in range(fSuc):
    files[j].close()
#if (oldData and fSuc == 10):
#    files = open(oldData,'w')
#    files.write(i)
#    files.close()

s = '''<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>Sysinfo</title>
<meta HTTP-EQUIV="REFRESH" CONTENT="<?php echo $updateTime;?>">
</head>
<body style="background-color: black; color: white; font-family: monospace;">
<center><h1>Collected system information by <?php echo date('H:i:s d.m.Y')?></h1></center>
<?php
$hdr = getallheaders();
$proxys = $hdr['X-NGX-VERSION'];
$hostnm = explode(' ', $_SERVER['SERVER_SOFTWARE']);
$server = $_SERVER['SERVER_ADDR'].":".$hdr['X-Apache-Port']." (".$hostnm[0].")";
$client = $hdr['X-Real-IP'].":".$hdr['X-Real-Port'];
$redirc = $_SERVER['REMOTE_ADDR'].":".$_SERVER['REMOTE_PORT'];
echo "<div align=\"right\">";
echo "<table style=\"color: aqua; font-weight: bold; margin-right: 20px;\">";
echo "<tr><td> nginx:</td><td>".$proxys."</td></tr>";
echo "<tr><td>apache:</td><td>".$server."</td></tr>";
echo "<tr><td>client (nginx side):</td><td>".$client."</td></tr>";
echo "<tr><td>client (apache side):</td><td>".$redirc."</td></tr>";
echo "</table></div>";
?>
<br>

<p>LoadAVG</p>
<table>
<tr><td>
{}
</td><td>
{}
</td><td>
{}
</td></tr>
</table>'''.format(loadavg[0],loadavg[1],loadavg[2])
s += '''<p>Iostat</p><table>'''
s+='''<tr><td>nameOfDisk</td><td>rrqm/s</td><td>wrqm/s</td><td>r/s</td><td>w/s</td><td>rkB/s</td><td>wkB/s</td><td>avgrq-sz</td><td>avgqu-sz</td><td>await</td><td>r_await</td><td>w_await</td><td>svctm</td><td>%util</td></tr>'''
for i in range(len(disk)):
    s += '''<tr>'''
    for j in range(14):
        s+='''<td>{}</td>'''.format(disk[i][j])
    s += '''</tr>'''
s+= '''</table>'''

s += '''<p>Net</p><table>'''
s += '''<tr><td>nameOfInterface</td><td>Recieved bytes</td><td>Recieved packets</td><td>Recieved errs</td><td>Recieved drop</td><td>Recieved fifo</td><td>Recieved frame</td><td>Recieved compressed</td><td>Recieved multicast</td><td>Transmitted bytes</td><td>Transmitted packets</td><td>Transmitted errs</td><td>Transmitted drop</td><td>Transmitted fifo</td><td>Transmitted colls</td><td>Transmitted carrier</td><td>Transmitted compressed</td></tr>'''
'''for i in range(len(net)):
    s += '''<tr>'''
    for j in range(len(net[i])):
        s+='''<td>{}</td>'''.format(net[i][j])
    s += '''</tr>'''
s+= '''</table>'''
s += '''<p>Connections:</p>'''
s+='''  <table>
        <tr><td>CLOSED: </td><td>{}</td><tr>
        <tr><td>LISTENING: </td><td>{}</td><tr>
        <tr><td>SYN_SENT: </td><td>{}</td><tr>
        <tr><td>SYN_RECEIVED: </td><td>{}</td><tr>
        <tr><td>ESTABLISHED: </td><td>{}</td><tr>
        <tr><td>CLOSE_WAIT: </td><td>{}</td><tr>
        <tr><td>FIN_WAIT_1: </td><td>{}</td><tr>
        <tr><td>CLOSING: </td><td>{}</td><tr>
        <tr><td>LAST_ACK: </td><td>{}</td><tr>
        <tr><td>FIN_WAIT_2: </td><td>{}</td><td>
        <tr><td>TIME_WAIT: </td><td>{}</td><tr></table>'''.format(closed,listen,syn_sent,syn_received,established,close_wait,fin_wait_1,closing,last_ack,fin_wait_2,time_wait)
'''

s += '''<p>NetStat</p><table>'''
s += '''<tr><td>Proto</td><td>Recv-Q</td><td>Send-Q</td><td>Local Address</td><td>Foreign Address </td><td>Stat</td></tr>'''
for i in range(len(netstat)):
    s += '''<tr>'''
    for j in range(len(netstat[i])):
        s+='''<td>{}</td>'''.format(netstat[i][j])
    s += '''</tr>'''
s+= '''</table>'''
#s += '''<p>CPU</p><table><tr><td>usr+nice</td><td>sys</td><td>idle</td><td>io</td></tr><tr>'''
#for i in range(len(cpu)):
#        s+='''<td>{}</td>'''.format(cpu[i])
#s+= '''</tr></table>'''




s += '''<p>TCPDump</p><table><tr><td>Proto</td><td>Bytes</td><td>%ofAll</td></tr>'''
allP = tcp+udp+icmp
allP = 1 if allP == 0 else allP
if (tcp > udp):
    if (tcp>icmp):
         if(udp>icmp):
            #tcp udp icmp
            s+='''<tr><td>TCP</td><td>{}</td><td>{}</td></tr>'''.format(tcp,tcp/allP*100)
            s+='''<tr><td>UDP</td><td>{}</td><td>{}</td></tr>'''.format(udp,udp/allP*100)
            s+='''<tr><td>ICMP</td><td>{}</td><td>{}</td></tr>'''.format(icmp,icmp/allP*100)
         else:
            #tcp icmp udp
            s+='''<tr><td>TCP</td><td>{}</td><td>{}</td></tr>'''.format(tcp,tcp/allP*100)
            s+='''<tr><td>ICMP</td><td>{}</td><td>{}</td></tr>'''.format(icmp,icmp/allP*100)
            s+='''<tr><td>UDP</td><td>{}</td><td>{}</td></tr>'''.format(udp,udp/allP*100)
    else:
        #icmp tcp udp
        s+='''<tr><td>ICMP</td><td>{}</td><td>{}</td></tr>'''.format(icmp,icmp/allP*100)
        s+='''<tr><td>TCP</td><td>{}</td><td>{}</td></tr>'''.format(tcp,tcp/allP*100)
        s+='''<tr><td>UDP</td><td>{}</td><td>{}</td></tr>'''.format(udp,udp/allP*100)
else:
    if (udp>icmp):
        if(tcp > icmp):
            #udp tcp icmp        
            s+='''<tr><td>UDP</td><td>{}</td><td>{}</td></tr>'''.format(udp,udp/allP*100)
            s+='''<tr><td>TCP</td><td>{}</td><td>{}</td></tr>'''.format(tcp,tcp/allP*100)
            s+='''<tr><td>ICMP</td><td>{}</td><td>{}</td></tr>'''.format(icmp,icmp/allP*100)
        else:
            #udp icmp tcp
            s+='''<tr><td>UDP</td><td>{}</td><td>{}</td></tr>'''.format(udp,udp/allP*100)
            s+='''<tr><td>ICMP</td><td>{}</td><td>{}</td></tr>'''.format(icmp,icmp/allP*100)
            s+='''<tr><td>TCP</td><td>{}</td><td>{}</td></tr>'''.format(tcp,tcp/allP*100)
    else:
        #icmp udp tcp
        s+='''<tr><td>ICMP</td><td>{}</td><td>{}</td></tr>'''.format(icmp,icmp/allP*100)
        s+='''<tr><td>UDP</td><td>{}</td><td>{}</td></tr>'''.format(udp,udp/allP*100)
        s+='''<tr><td>TCP</td><td>{}</td><td>{}</td></tr>'''.format(tcp,tcp/allP*100)
s += '''</table><table>'''
for i in range(len(tcpdump)):
    tcpdump[i].append(tcpdump[i][0][0])
    tcpdump[i].append(tcpdump[i][0][1])
    del tcpdump[i][0]
    tcpdump[i][0] = int(tcpdump[i][0])
    tcpdump[i][1] = int(tcpdump[i][1])
tcpdump.sort()
s+='''<tr><td>Packets</td><td>Bytes</td><td>IP1</td><td>IP2</td></tr>'''
for i in range(len(tcpdump)):
    s += '''<tr>'''
    for j in range(len(tcpdump[i])):
        s+='''<td>{}</td>'''.format(tcpdump[i][j])
    s += '''</tr>'''
s+= '''</table><table>'''
for i in range(len(tcpdump)):
    tcpdump[i][1],tcpdump[i][0] = tcpdump[i][0],tcpdump[i][1]
tcpdump.sort()
s+='''<tr><td>Bytes</td><td>Packets</td><td>IP1</td><td>IP2</td></tr>'''
for i in range(len(tcpdump)):
    s += '''<tr>'''
    for j in range(len(tcpdump[i])):
        s+='''<td>{}</td>'''.format(tcpdump[i][j])
    s += '''</tr>'''
s+= '''</table>'''



s += '''<p>DiskSpace</p><table>'''
s += '''<tr><td>fileSystem</td><td>Mount</td><td>FreeSpace</td><td>FreeInodes</td></tr>'''
for i in range(len(diskSpace)):
    s += '''<tr>'''
    for j in range(len(diskSpace[i])):
        s+='''<td>{}</td>'''.format(diskSpace[i][j])
    s += '''</tr>'''
s+= '''</table>'''

s += '''</body>
</html>'''
files = open('/var/www/index.html','w')
files.write(s)
files.close()
