# Echo client program
import socket
import sys
import json
import time
import datetime
import math
import requests

HOST = 'fec0::2'    # The remote host
PORT = 2000    
before = datetime.datetime.now()
          # The same port as used by the server


def postTweet(after,data):
    global before
    diff  = math.floor(((after - before).seconds) )
    if diff > 60 :
        before = datetime.datetime.now()
        url = 'https://zapier.com/hooks/catch/n/t30ye/'
        payload = data
        headers = {'content-type': 'application/json'}
        r = requests.post(url, data=json.dumps(payload), headers=headers)
	#print data
s = None
for res in socket.getaddrinfo(HOST, PORT, socket.AF_UNSPEC, socket.SOCK_DGRAM):
    af, socktype, proto, canonname, sa = res
    try:
        s = socket.socket(af, socktype, proto)
    except socket.error as msg:
        s = None
        continue
    try:
        s.connect(sa)
    except socket.error as msg:
        s.close()
        s = None
        continue
    break
if s is None:
    print 'could not open socket'
    sys.exit(1)
s.sendall('help\n')
while 1:
    data = s.recv(1024)
    try:
        dd=(data.rstrip(' \t\r\n\0'))
        jobj= json.loads(dd)
       
        t=time.strftime('%c')
        jobj['timestamp']=t
        after = datetime.datetime.now()
        postTweet(after,jobj)
        print jobj
        
        #hours  = math.floor(((after - before).seconds) )
        #print hours
    except ValueError, err:
        continue
        #print 'ERROR:', err
    #print 'Received', repr(data)

s.close()

