#!/bin/bash

NODE_ID_DIR="/var/scratch/ebohte/node_id/temp"

echo "start id ${1}"

export IPFS_PATH=/var/scratch/ebohte/.ipfs"${1}" #1 NODE_ID
/home/ebohte/ipfs/ipfs init

/home/ebohte/ipfs/ipfs bootstrap rm --all
/home/ebohte/ipfs/ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/56003
/home/ebohte/ipfs/ipfs config Addresses.API /ip4/127.0.0.1/tcp/63781
echo "${1}: config done."

tmux new-session -s ipfs -d
tmux send -t ipfs export SPACE IPFS_PATH=/var/scratch/ebohte/.ipfs"${1}" ENTER #1 NODE_ID
tmux send -t ipfs /home/ebohte/ipfs/ipfs SPACE daemon ENTER
echo "${1}: ipfs started"

if [ ! -d "${NODE_ID_DIR}" ]; then
	mkdir -p "${NODE_ID_DIR}"
    echo "${1} created ${NODE_ID_DIR}"
fi

/home/ebohte/ipfs/ipfs id > /var/scratch/ebohte/node_id/temp/node_id_"${1}".txt #1 NODE_ID
ID_LINES=$( cat /var/scratch/ebohte/node_id/temp/node_id_"${1}".txt | wc -l )
while [[ ID_LINES -lt 11 ]]; do
	sleep 0.5
    /home/ebohte/ipfs/ipfs id > /var/scratch/ebohte/node_id/temp/node_id_"${1}".txt #1 NODE_ID
    ID_LINES=$( cat /var/scratch/ebohte/node_id/temp/node_id_"${1}".txt | wc -l )
done
/home/ebohte/ipfs/ipfs id > /var/scratch/ebohte/node_id/node_id_"${1}".txt #1 NODE_ID
echo "${1}: wrote id"


while [ ! -f /var/scratch/ebohte/node_id/all_ipfs_node_ids.txt ]
do
   sleep 0.2
done

NODE_IDS=$( cat /var/scratch/ebohte/node_id/all_ipfs_node_ids.txt )
ADD_ALL_COMMAND="/home/ebohte/ipfs/ipfs bootstrap add ${NODE_IDS}"
eval $ADD_ALL_COMMAND
echo "${1}: added all nodes"

while [ ! -f /home/ebohte/output/large_file_50.txt ]
do
   sleep 2
done

echo "${1}: shutdown passive"
