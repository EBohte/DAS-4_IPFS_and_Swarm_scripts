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

tmux send -t Swarm${1} $COMMANDDIR/geth SPACE --datadir SPACE $DATADIR SPACE --networkid SPACE 8889 SPACE --port SPACE $gethPort SPACE console ENTER;
echo "${1}: start geth"
sleep 30
tmux send -t Swarm$added $COMMANDDIR/swarm SPACE --bzzaccount SPACE $(ls $DATADIR/keystore/ | awk -F'[-]' '{print $9}') SPACE --datadir SPACE $DATADIR/ SPACE --keystore SPACE $DATADIR/keystore SPACE --password SPACE /var/scratch/sroobol/go/src/github.com/ethereum/go-ethereum/BZZ/BZZ/password SPACE --port SPACE $swarmPort ENTER;
echo "${1}: start swarm"
sleep 60

ENODE=$( $COMMANDDIR/geth --exec 'console.log(admin.nodeInfo.enode)' attach ipc://$DATADIR/bzzd.ipc )

sleep 1

while [[ $ENODE == *"connection refused"* ]]; do
    echo "${1}: waiting for geth and swarm to connection"
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

EXPECTED_FILES="150"

echo "${1}: expected files $EXPECTED_FILES"
NUMBER_OF_FILES=$( ls /home/sroobol/output/3 | wc -l )
while [[ NUMBER_OF_FILES -lt EXPECTED_FILES ]]; do
    sleep 0.1
    NUMBER_OF_FILES=$( ls /home/sroobol/output/3 | wc -l )
#    echo "${1}: number of files $NUMBER_OF_FILES"
done
