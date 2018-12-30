from os import listdir
from os.path import isfile, join
import json
import sys
import re

if len(sys.argv) is 2:
    mypath=sys.argv[1]
else:
    print "give the directory with all the node ids."


id_files = [f for f in listdir(mypath) if isfile(join(mypath, f)) and "node_id" in f]
print "Got all node files"


output = open(join(mypath, 'all_ipfs_node_ids.txt'), 'w+')
print "opened output file"

for file in id_files:
    print "opened: " + str(file)
    temp_file = open(join(mypath,file))
    data = json.load(temp_file)
    addrs = data['Addresses']
    try:
        for addr in addrs:
            if re.match('/ip4/10.141.[.\d.\d]+/tcp/4001/ipfs/[\w]*', addr):
               addr_found = addr
        output.write(addr_found)
        output.write(" ")
    except:
        print "Something went wrong with addrs " + str(addrs)

print "added all the node ids to the file"

output.close()

print "closed output file"
