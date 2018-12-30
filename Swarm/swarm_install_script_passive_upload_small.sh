#!/bin/bash

export DATADIR="/var/scratch/sroobol/go/src/github.com/ethereum/go-ethereum/BZZ/BZZ/DATADIR${1}"
export COMMANDDIR="/var/scratch/sroobol/go/bin"

ENODE_DIR="/var/scratch/sroobol/enodes"

added=$[${1}+30]

tmux new-session -d -s Swarm${1}
tmux new-session -d -s Swarm$added
sleep 0.5

swarmPort=$[${1}+50000]
gethPort=$[${1}+5000]

tmux send -t Swarm$added $COMMANDDIR/geth SPACE --datadir SPACE $DATADIR SPACE --networkid SPACE 8889 SPACE --port SPACE $gethPort SPACE console ENTER;
echo "${1}: start geth"
sleep 30
tmux send -t Swarm${1} $COMMANDDIR/swarm SPACE --bzzaccount SPACE $(ls $DATADIR/keystore/ | awk -F'[-]' '{print $9}') SPACE --datadir SPACE $DATADIR/ SPACE --keystore SPACE $DATADIR/keystore SPACE --password SPACE /var/scratch/sroobol/go/src/github.com/ethereum/go-ethereum/BZZ/BZZ/password SPACE --port SPACE $swarmPort ENTER;
echo "${1}: start swarm"
sleep 60

ENODE=$( $COMMANDDIR/geth --exec 'console.log(admin.nodeInfo.enode)' attach ipc://$DATADIR/bzzd.ipc )

sleep 1

while [[ $ENODE == *"connection refused"* ]]; do
    echo "{1}: waiting for geth and swarm to connection"
    sleep 1
    ENODE=$( $COMMANDDIR/geth --exec 'console.log(admin.nodeInfo.enode)' attach ipc://$DATADIR/bzzd.ipc )
done

if [ ! -d "${ENODE_DIR}" ]; then
    mkdir -p "${ENODE_DIR}"
    echo "${1} created ${ENODE_DIR}"
fi

echo $ENODE > /var/scratch/sroobol/enodes/enodes_"${1}".txt
echo "${1}: wrote ${ENODE} to file"
sleep 1

N_F=$( ls /var/scratch/sroobol/enodes/ -p | grep -v / | wc -l )
while [ $N_F -ne "${2}" ] #NUMBER OF NODES
do
    sleep 0.5
    N_F=$( ls /var/scratch/sroobol/enodes/ -p | grep -v / | wc -l )
    echo "${1}: waiting for all nodes to write id"
done

cat /var/scratch/sroobol/enodes/enode*.txt >> /var/scratch/sroobol/enodes/all_enodes.txt

while [ ! -f /var/scratch/sroobol/enodes/all_enodes.txt ]
do
    sleep 0.5
done


regex="enode:\/\/(.*)@(.*):(.*) undefined"

while IFS= read -r line; do
        if [[ $line =~ $regex ]]
        then
                enode="${BASH_REMATCH[1]}"
                ip="${BASH_REMATCH[2]}"
                port="${BASH_REMATCH[3]}"
                $COMMANDDIR/geth --exec='admin.addPeer("enode://'"$enode"'@'"$ip"':'"$port"'")' attach $DATADIR/bzzd.ipc
        fi
done < /var/scratch/sroobol/enodes/all_enodes.txt

#echo "${1}: start uploading small"
#for i in `seq 1 50`;
#do
#	OUTPUT=$( { time $COMMANDDIR/swarm up /var/scratch/sroobol/files/small_file.txt; } 2>&1 )
#	echo "${OUTPUT}" >> /home/sroobol/output/small_file_$i.txt
#	echo "${1}: uploaded small file"
#done

#echo "${1}: start uploading medium"
#for i in `seq 1 50`;
#do
#        OUTPUT=$( { time $COMMANDDIR/swarm up /var/scratch/sroobol/files/medium_file.txt; } 2>&1 )
#        echo "${OUTPUT}" >> /home/sroobol/output/med_file_$i.txt
#        echo "${1}: uploaded medium file"
#done

for i in `seq 38 50`;
do
        OUTPUT=$( { time $COMMANDDIR/swarm up /var/scratch/sroobol/files/large_file.txt; } 2>&1 )
        echo "${OUTPUT}" >> /home/sroobol/output/large_file_$i.txt
        echo "${1}: uploaded large file"
done

#echo "${1}: start uploading dir"
#for i in `seq 1 50`;
#do
#        OUTPUT=$( { time $COMMANDDIR/swarm --recursive up /var/scratch/sroobol/files/combination; } 2>&1 )
#        echo "${OUTPUT}" >> /home/sroobol/output/combination_file_$i.txt
#        echo "${1}: combination dir"
#done

