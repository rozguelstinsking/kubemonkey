#!/bin/bash

COUNT_MIN=0

# ROUTE=https://agro-front-mxdrp-dev.appls.boaw.paas.gsnetcloud.corp
ROUTE=https://agro-front-produbanmx-dev.appls.cto1.paas.gsnetcloud.corp;

POLL_SVC_ZONE=https://api.cto1.paas.gsnetcloud.corp:8443
DEPLOY_ZONE=https://api.boaw.paas.gsnetcloud.corp:8443

DC_FILE=""
SNAMESPACE=produbanmx-dev
DC=""
FQDN=""

PSWD=$(
  sed '
    s/[[:space:]]\{1,\}/ /g; # turn sequences of spacing characters into one SPC
    s/[^[:print:]]//g; # remove non-printable characters
    s/^ //; s/ $//; # remove leading and trailing space
    q; # quit after first line' < fpass
)

function create_copy_yml(){
	echo "-------------------------------------- will login into $POLL_SVC_ZONE"
	oc login -u x916511 -p $PSWD $POLL_SVC_ZONE
	oc project $SNAMESPACE
	FQDN=$(echo $ROUTE | sed 's/\:\/\//#/g' | cut -d '#' -f 2)
	DC=$(oc get routes | grep $FQDN | awk '{print $1}')
	oc export dc $DC > dc-$DC.yml
}

function redirect_proxy(){
	IP_1=192.168.0.15
	IP_2=0.0.0.0
	PORT_1=80
	PORT_2=8080
	SRVR_DNS_IP1_ACTIVE="server  app1 ${IP_1}\:${PORT_1} check"
	SRVR_DNS_IP1_DEACTIVE="#server  app1 ${IP_1}\:${PORT_1} check"
	SRVR_DNS_IP2_ACTIVE="server  app1 ${IP_2}\:${PORT_2} check"
	SRVR_DNS_IP2_DEACTIVE="#server  app1 ${IP_2}:${PORT_2} check"
	
	# TODO CHANGE IPS in proxy and restart
	sudo systemctl restart haproxy
	
}

function create_new_app_from(){
	create_copy_yml
	sleep 90
	#Login into BOAW
	oc login -u x916511 -p $PSWD $DEPLOY_ZONE
	#DEPLOY backup yml
	oc create -f dc-$DC.yml
	#Change route .- delete svc
	sleep 60
	oc expose dc $DC 
	#expose dc created
	sleep 60 
	oc expose svc $DC 
}



function poll_ms(){
	COUNT_MIN=`expr $COUNT_MIN + 1`
	echo "Into polling service"
	RES_POLL=$(curl -k $ROUTE | grep "Application is not available")
	echo $RES_POLL
	if [ "$RES_POLL" != "" ]
	then
		echo "RESTORE ENVIRONMENT"
		if [ "$COUNT_MIN" -eq 3 ]
		then
			create_new_app_from
		else
			poll_ms
			sleep 60
		fi  
	else
		echo "SITE IS RESPONDING"
	fi
	
}



# MAIN CONFIG

poll_ms
