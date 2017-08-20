#!/usr/bin/python
import re
import sys

print ("Evaluating probablity from trace file!")
with open("randommac.tr") as f :
	each_line = f.read().split('\n')
	stringarray = []
for line in each_line :
	fields = line.split(' ')
	if ((fields[0] in ['s','r','D']) and (fields[3] == 'MAC') and (fields[7] == 'cbr')) :
		stringarray.append({'event_type':fields[0],'node_id':fields[2],'packet_uid':int(fields[6])})
unique_sent = len(set(entry['packet_uid'] for entry in stringarray))
print("Number of unique packets sent is %d" %unique_sent)
unique_received = len(set(entry['packet_uid'] for entry in stringarray if entry['event_type'] == 'r' and entry['node_id'] == "_0_"))
print("Number of unique packets received is %d" %unique_received)
print("Probability is %0.3f%%"%float(unique_received * 100.0/unique_sent))

X = str(sys.argv[1])
Y = float(unique_received * 100.0/unique_sent)
Y = Y/100.0
str_Y = "{:.3f}".format(Y) 
fl = open('stat.txt','a')

content = X+' '+str_Y+'\n'
fl.write(content)
           
fl.close()
