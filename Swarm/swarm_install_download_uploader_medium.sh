#!/bin/bash
DATADIR="/var/scratch/sroobol/go/src/github.com/ethereum/go-ethereum/BZZ/BZZ/DATADIR${1}" 
COMMANDDIR="/var/scratch/sroobol/go/bin" 
NODEDIR="/var/scratch/sroobol/enodes" 

added=$[${1}+30] 

tmux new-session -d -s Swarm${1} 
tmux new-session -d -s Swarm$added 
sleep 0.5 

swarmPort=$[${1}+50000] 
gethPort=$[${1}+5000] 

tmux send -t Swarm${1} $COMMANDDIR/geth SPACE --datadir SPACE $DATADIR SPACE --networkid SPACE 8889 SPACE --port SPACE $gethPort SPACE console ENTER; 
echo "${1}: started geth node" 
sleep 30 

tmux send -t Swarm$added $COMMANDDIR/swarm SPACE --bzzaccount SPACE $(ls $DATADIR/keystore/ | awk -F'[-]' '{print $9}') SPACE --datadir SPACE $DATADIR/ SPACE --keystore SPACE $DATADIR/keystore SPACE --password SPACE /var/scratch/sroobol/go/src/github.com/ethereum/go-ethereum/BZZ/BZZ/password SPACE --port SPACE $swarmPort ENTER; 
echo "${1}: added swarm account to blockchain" 
sleep 60

ENODE=$( $COMMANDDIR/geth --exec 'console.log(admin.nodeInfo.enode)' attach ipc://$DATADIR/bzzd.ipc ) 
sleep 1 

while [[ $ENODE == *"connection refused"* ]]; 
do
    echo "${1}: waiting for geth and swarm to start up"
    sleep 1
    ENODE=$( $COMMANDDIR/geth --exec 'console.log(admin.nodeInfo.enode)' attach ipc://$DATADIR/bzzd.ipc ) 
done 

if [ ! -d "$NODEDIR" ]; 
then
    mkdir -p "$NODEDIR"
    echo "${1}: created the enode directory" 
fi 

echo $ENODE > $NODEDIR/enodes_${1}.txt 
echo "wrote $ENODE to file enodes_${1}.txt" 
sleep 1 

N_F=$( ls $NODEDIR -p | grep -v / | wc -l )
while ["$N_F" -ne "${2}" ]; 
do
    sleep 0.5
    N_F=$(ls $NODEDIR -p | grep -v / | wc -l )
    echo "${1}: waiting for all enodes to write address" 
done 

cat $NODEDIR/enode*.txt >> $NODEDIR/all_enodes.txt 

while [ ! -f $NODEDIR/all_enodes.txt ]; 
do
    sleep 0.5 
done 

regex="enode:\/\/(.*)@(.*):(.*) undefined" 

while IFS= read -r line; 
do
    if [[ $line =~ $regex ]]
    then
        enode="${BASH_REMATCH[1]}"
        ip="${BASH_REMATCH[2]}"
        port="${BASH_REMATCH[3]}"
        $COMMANDDIR/geth --exec='admin.addPeer("enode://'"$enode"'@'"$ip"':'"$port"'")' attach $DATADIR/bzzd.ipc
    fi 
done < $NODEDIR/all_enodes.txt 

#echo "${1}: uploading small file ..." 
#OUTPUT=$( $COMMANDDIR/swarm up /var/scratch/sroobol/files/medium_file.txt ) 
#echo "${OUTPUT}" > /var/scratch/sroobol/hash/medium_hash.txt 
#echo "${1}: uploaded medium file hash" 

while [ ! -f /home/sroobol/output/medium_file_download_50.txt ]; 
do
   sleep 2 
done
 
echo "${1}: shutdown uploader"
