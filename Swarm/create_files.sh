#!/bin/bash

mkdir -p /var/scratch/ebohte/files/

head -c 2MB /dev/urandom > /var/scratch/ebohte/files/small_file.txt
echo 'Created 2MB file.'
head -c 750MB /dev/urandom > /var/scratch/ebohte/files/medium_file.txt
echo 'Created 750MB file.'
head -c 4700MB /dev/urandom > /var/scratch/ebohte/files/large_file.txt
echo 'Created 4700MB file.'

list_sizes_command=("head -c 67KB /dev/urandom" "head -c 78KB /dev/urandom" "head -c 375KB /dev/urandom")
list_sizes=(67 78 375)

total=2000
rotation=0

mkdir -p /var/scratch/ebohte/files/combination

echo 'Creating random files'

while [ $total -gt 0 ];
do
    random="$(shuf -i 0-2 -n 1)"
    ${list_sizes_command[$random]} > /var/scratch/ebohte/files/combination/$rotation
    ((rotation++))
    ((total-=${list_sizes[$random]}))
    echo "added a file of ${list_sizes[$random]} KB" 
done
