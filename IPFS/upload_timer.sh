#!/bin/bash

NODE_ID_DIR="/var/scratch/ebohte/node_id/temp"
OUTPUT_DIR="/home/ebohte/output/"

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

# wait till there are x files in a directory
N_F=$( ls /var/scratch/ebohte/node_id -p | grep -v / | wc -l )
while [ "$N_F" -ne "$2" ] #NUMBER OF NODES
do
    sleep 0.5
    N_F=$( ls /var/scratch/ebohte/node_id -p | grep -v / | wc -l )
    echo "${1}: waiting for all nodes to write id"
done

echo "${1}: start combining the ids"
python /home/ebohte/combine_ids.py /var/scratch/ebohte/node_id
echo "${1}: combined all the ids"

while [ ! -f /var/scratch/ebohte/node_id/all_ipfs_node_ids.txt ]
do
    sleep 0.5
done

NODE_IDS=$( cat /var/scratch/ebohte/node_id/all_ipfs_node_ids.txt )
ADD_ALL_COMMAND="/home/ebohte/ipfs/ipfs bootstrap add ${NODE_IDS}"
eval $ADD_ALL_COMMAND
echo "${1}: added all nodes"


bash /home/ebohte/create_file.sh

if [ ! -d "${OUTPUT_DIR}" ]; then
    mkdir -p "${OUTPUT_DIR}"
    echo "${1} created ${OUTPUT_DIR}"
fi

#for loop small file
for i in `seq 1 50`;
do
    OUTPUT="$( { time /home/ebohte/ipfs/ipfs add /var/scratch/ebohte/files/small_file.txt --quiet; } 2>&1 )"
    echo "${OUTPUT}" > /home/ebohte/output/small_file_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
done
echo "${1}: uploaded small file"

#for loop medium file
for i in `seq 1 50`;
do
    OUTPUT=$( { time /home/ebohte/ipfs/ipfs add /var/scratch/ebohte/files/medium_file.txt --quiet; } 2>&1 )
    echo "${OUTPUT}" > /home/ebohte/output/medium_file_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
done
echo "${1}: uploaded medium file"

#for loop big file
for i in `seq 1 50`;
do
    OUTPUT=$( { time /home/ebohte/ipfs/ipfs add /var/scratch/ebohte/files/large_file.txt --quiet; } 2>&1 )
    echo "${OUTPUT}" > /home/ebohte/output/large_file_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
done
echo "${1}: uploaded large file"

#for loop dir
for i in `seq 1 50`;
do
    OUTPUT=$( { time /home/ebohte/ipfs/ipfs add /var/scratch/ebohte/files/combination/ -r --quiet; } 2>&1 )
    echo "${OUTPUT}" > /home/ebohte/output/combination_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
done
echo "${1}: uploaded combination file"

echo "${1}: shutdown"

