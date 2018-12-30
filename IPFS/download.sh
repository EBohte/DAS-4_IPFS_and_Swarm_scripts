#!/bin/bash

NODE_ID_DIR="/var/scratch/ebohte/node_id/temp"
HASH_DIR="/var/scratch/ebohte/hash/"

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
    echo "${1}: created ${NODE_ID_DIR}"
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

if [ ! -d "${HASH_DIR}" ]; then
    mkdir -p "${HASH_DIR}"
    echo "${1}: created ${HASH_DIR}"
fi

while [ ! -f /var/scratch/ebohte/hash/large_hash.txt ]
do
   sleep 2
   echo "${1}: waiting for hash"
done

if [ ! -d "${OUTPUT_DIR}" ]; then
    mkdir -p "${OUTPUT_DIR}"
    echo "${1} created ${OUTPUT_DIR}"
fi

SMALL_HASH=$( cat /var/scratch/ebohte/hash/small_hash.txt )
for i in `seq 1 50`;
do
    OUTPUT=$( { time /home/ebohte/ipfs/ipfs get "${SMALL_HASH}" -o /dev/null; } 2>&1 )
    echo "${OUTPUT}" > /home/ebohte/output/small_file_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
    echo "${1}: got small file ${i}"
done
echo "${1}: small file done"

MED_HASH=$( cat /var/scratch/ebohte/hash/medium_hash.txt )
for i in `seq 1 50`;
do
    OUTPUT=$( { time /home/ebohte/ipfs/ipfs get "${MED_HASH}" -o /dev/null; } 2>&1 )
    echo "${OUTPUT}" > /home/ebohte/output/med_file_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
    echo "${1}: got med file ${i}"
done
echo "${1}: med file done"

LARGE_HASH=$( cat /var/scratch/ebohte/hash/large_hash.txt )
for i in `seq 1 50`;
do
    echo "${1}: start downloading"
    OUTPUT=$( { time /home/ebohte/ipfs/ipfs get "${LARGE_HASH}" -o /dev/null; } 2>&1 )
    echo "${OUTPUT}" > /home/ebohte/output/large_file_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
    echo "${1}: got large file ${i}"
done
echo "${1}: large file done"

COMBI_HASH=$( tail -1 /var/scratch/ebohte/hash/combination_hash.txt )
echo "HASH: ${COMBI_HASH}"
mkdir -p /var/scratch/ebohte/temp_dir/
for i in `seq 1 50`;
do
    OUTPUT=$( { time /home/ebohte/ipfs/ipfs get "${COMBI_HASH}" -o /var/scratch/ebohte/temp_dir/; } 2>&1 )
    echo "${OUTPUT}" > /home/ebohte/output/combi_file_"${i}".txt
    /home/ebohte/ipfs/ipfs pin ls --type recursive | cut -d' ' -f1 | xargs -n1 /home/ebohte/ipfs/ipfs pin rm # remove all pinned files
    /home/ebohte/ipfs/ipfs repo gc
    rm -rf /var/scratch/ebohte/temp_dir/*
    echo "${1}: got combi file ${i}"
done
echo "${1}: combi file done"

echo "${1}: shutdown downloader" 