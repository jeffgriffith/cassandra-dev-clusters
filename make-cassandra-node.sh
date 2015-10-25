#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <nodenum>"
	exit 1
fi

NODENUM=${1}
BASEDIR=apache-cassandra-2.1.11
NEWDIR=apache-cassandra-2.1.11-node${NODENUM}
LISTEN_ADDRESS=127.0.0.${NODENUM}
RPC_ADDRESS=${LISTEN_ADDRESS}
NUM_TOKENS=3
JMX_PORT=$( expr 7199 + 10000 \* ${NODENUM} )


#echo NODENUM=${NODENUM}
#echo LISTEN_ADDRESS=${LISTEN_ADDRESS}
#echo RPC_ADDRESS=${RPC_ADDRESS}
#echo NUM_TOKENS=${NUM_TOKENS}
#echo JMX_PORT=${JMX_PORT}

function assert_loopback_alias_exists {
	ifconfig lo0 | grep $LISTEN_ADDRESS >/dev/null
	if [ "$?" -ne "0" ] ; then
		echo "Enternet loopback not aliased. Try..."
		echo "    sudo ifconfig lo0 alias ${LISTEN_ADDRESS}"
		exit 1
	fi
}

function copy_virgin_directory {
	if [ -d ${NEWDIR} ]; then
		echo "${NEWDIR} already exists."
		exit 1
	fi

	echo "Copying ${BASEDIR} to ${NEWDIR}..."
	cp -R ${BASEDIR} ${NEWDIR}
}

function fix_cassandra_env {
	cat ${BASEDIR}/conf/cassandra-env.sh | \
		sed "s/JMX_PORT=\"7199\"/JMX_PORT=\"${JMX_PORT}\"/" \
		> ${NEWDIR}/conf/cassandra-env.sh
	
	echo "\nMODIFIED cassandra-env.sh like this......"
	echo "========================================="
	diff ${BASEDIR}/conf/cassandra-env.sh ${NEWDIR}/conf/cassandra-env.sh
}

function fix_cassandra_yaml {
	cat ${BASEDIR}/conf/cassandra.yaml | \
		sed "s/num_tokens: 256/num_tokens: 3/" | \
		sed "s/listen_address: localhost/listen_address: ${LISTEN_ADDRESS}/" | \
		sed "s/rpc_address: localhost/rpc_address: ${RPC_ADDRESS}/" \
		> ${NEWDIR}/conf/cassandra.yaml

	echo "\nMODIFIED cassandra.yaml like this......"
	echo "======================================="
	diff ${BASEDIR}/conf/cassandra.yaml ${NEWDIR}/conf/cassandra.yaml
}

assert_loopback_alias_exists
copy_virgin_directory
fix_cassandra_yaml
fix_cassandra_env

echo "\nDONE."
