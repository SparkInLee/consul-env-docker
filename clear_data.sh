#!/bin/bash

cd $(dirname $0)
BASE_DIR=$(pwd)
DIR_NAME=$1

usage(){
	echo "usage:"
	echo "clear_data dir1 dir2..."
}

if [ -z "$DIR_NAME" ]
then
	usage
	exit 1
fi

for dir in $@
do
	if [ -e "$BASE_DIR/data/$dir" ]
	then
		cd "$BASE_DIR/data/$dir"
		realDir=$(pwd)
		if [[ $realDir == $BASE_DIR/data/* ]]
		then
			echo "clear $BASE_DIR/data/$dir"
			rm -rf *
		else
			echo "illegal directory: $dir"
		fi
	else
		echo "directory not exist $dir"
	fi
done
