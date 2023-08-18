#!/bin/bash 

WAIT=${1:-10}

DATA_DIR_RAW=data/raw/
DATA_DIR_HEX=data/hex/
DATA_DIR_DEC=data/dec/

BRIDGE_HOST=192.168.127.169
BRIDGE_USER=admin
BRIDGE_PASS=AJM2-BDBD

NODE_ID=1

echo "Waittime requested: $WAIT"

if [ ! -d $DATA_DIR_RAW ]; then
	echo "Creating raw data dir $DATA_DIR_RAW"
 	mkdir -p $DATA_DIR_RAW
fi

if [ ! -d $DATA_DIR_HEX ]; then
	echo "Creating hex data dir $DATA_DIR_HEX"
 	mkdir -p $DATA_DIR_HEX
fi

if [ ! -d $DATA_DIR_DEC ]; then
	echo "Creating decoded data dir $DATA_DIR_DEC"
 	mkdir -p $DATA_DIR_DEC
fi

CNT=1

while true; do
	prefix=$(date "+%Y%m%d_%H%M%S")

	RAW_FILE=$DATA_DIR_RAW/${prefix}.raw
	HEX_FILE=$DATA_DIR_HEX/${prefix}.hex
	DEC_FILE=$DATA_DIR_DEC/${prefix}.txt

	printf "[%05d] Getting $RAW_FILE" $CNT

	curl -s -u $BRIDGE_USER:$BRIDGE_PASS http://$BRIDGE_HOST/data.json?node_id=${NODE_ID} >> $RAW_FILE

	FILESIZE=$(stat -c "%s" $RAW_FILE)
	FILESUM=$(sha256sum $RAW_FILE)

	cat $RAW_FILE | python3 pysmlparser.py > $DEC_FILE
	TEST=$?
	
	printf " (%3d %6s)" $FILESIZE ${FILESUM:0:6}

	if [ $TEST -eq 0 ]; then
		echo -n " -> Test OK  "
		echo "[ OK ] $prefix" >> sml_get.log
	else
		echo -n " -> Test FAIL"
		echo "[FAIL] $prefix" >> sml_get.log
		echo "$prefix [RET:$TEST]" >> sml_get.failed
	fi

	echo " -> Creating $HEX_FILE"

	cat $RAW_FILE | xxd -g 1 > $HEX_FILE

	if [ $WAIT -eq 0 ]; then 
		echo "Single shot requested. Exiting"
		exit
	fi
	sleep $WAIT
	let CNT++
done

