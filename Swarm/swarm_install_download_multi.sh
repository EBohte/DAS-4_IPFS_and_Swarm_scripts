#!/bin/bash
DATADIR="/var/scratch/sroobol/go/src/github.com/ethereum/go-ethereum/BZZ/BZZ/DATADIR${1}"
COMMANDDIR="/var/scratch/sroobol/go/bin"
OUTPUT_DIR="/home/sroobol/output/3"
 
added=$[${1}+30]
 
tmux new-session -d -s Swarm${1}
tmux new-session -d -s Swarm$added
sleep 0.5
swarmPort=$[${1}+50000]
gethPort=$[${1}+5000]
 
tmux send -t Swarm${1} $COMMANDDIR/geth SPACE --datadir SPACE $DATADIR SPACE --networkid SPACE 8889 SPACE --port SPACE $gethPort SPACE console ENTER;
echo "${1}: started geth node"
sleep 30
 
tmux send -t Swarm$added $COMMANDDIR/swarm SPACE --bzzaccount SPACE $(ls $DATADIR/keystore/ | awk -F'[-]' '{print $9}') SPACE --datadir SPACE $DATADIR SPACE --keystore SPACE $DATADIR/keystore SPACE --password SPACE /var/scratch/sroobol/go/src/github.com/ethereum/go-ethereum/BZZ/BZZ/password SPACE --port SPACE $swarmPort ENTER;
echo "${1}: added swarm account to blockchain"
sleep 60
 
ENODE=$( $COMMANDDIR/geth --exec 'console.log(admin.nodeInfo.enode)' attach ipc://$DATADIR/bzzd.ipc )
sleep 1
 
while [[ $ENODE == *"connection refused"* ]]; do
    echo "${1}: waiting for geth and swarm to start up"
    sleep 1
    ENODE=$( $COMMANDDIR/geth --exec 'console.log(admin.nodeInfo.enode)' attach ipc://$DATADIR/bzzd.ipc )
done
 
echo $ENODE > /var/scratch/sroobol/enodes/enodes_"${1}".txt
echo "${1}: wrote ${ENODE} to file"
sleep 1
 
N_F=$( ls /var/scratch/sroobol/enodes/ -p | grep -v / | wc -l )
 
while [[ $N_F -ne "${2}" ]] && [[ ! -f /var/scratch/sroobol/enodes/all_enodes.txt ]]
do
    sleep 0.5
    N_F=$( ls /var/scratch/sroobol/enodes/ -p | grep -v / | wc -l )
    echo "${1}: waiting for all enodes to write address"
done

if [ ! -f /var/scratch/sroobol/enodes/all_enodes.txt ]; then
	cat /var/scratch/sroobol/enodes/enode*.txt >> /var/scratch/sroobol/enodes/all_enodes.txt
fi

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
 
#while [ ! -f /var/scratch/sroobol/hash/medium_hash.txt ]; do
#   sleep 2
#   echo "${1}: waiting for hash"
#done
 
#MEDIUM_HASH=$( { cat /var/scratch/sroobol/hash/medium_hash.txt; } 2>&1 )
 
if [ ! -d "${OUTPUT_DIR}" ]; then
    mkdir -p "${OUTPUT_DIR}"
    echo "${1} created ${OUTPUT_DIR}"
fi
 
 
for i in `seq 1 50`;
do
    echo "${1}: downloading file ${i} ... "
    OUTPUT=$( { time $COMMANDDIR/swarm down bzz://eb284b482865b3ca35a14751be3bdb055408a423cd6b39c894b6b1b9702608af /dev/null; } 2>&1 )
    echo "$OUTPUT"
    echo "$OUTPUT" >> /home/sroobol/output/3/multi_file_download_${i}_${1}.txt
    echo "${1}: got multi file $i"
done
echo "${1}: multi file done"

EXPECTED_FILES="150"
echo "${1}: expected files $EXPECTED_FILES"
NUMBER_OF_FILES=$( ls /home/sroobol/output/3 | wc -l )
while [[ $NUMBER_OF_FILES -lt $EXPECTED_FILES ]]; do
	sleep 0.1
	NUMBER_OF_FILES=$( ls /home/sroobol/output/3 | wc -l )
	echo "${1}: number of files $NUMBER_OF_FILES"
done
 
echo "${1}: shutdown downloader"
