#!/bin/bash

COUNT_MIN=0

# ROUTE=agro-front-mxdrp-dev.appls.boaw.paas.gsnetcloud.corp
ROUTE=agro-front-produbanmx-dev.appls.cto1.paas.gsnetcloud.corp

POLL_SVC_ZONE=https://api.cto1.paas.gsnetcloud.corp:8443
DEPLOY_ZONE=https://api.boaw.paas.gsnetcloud.corp:8443

# Hard coded vars
DC_FILE=""
SNAMESPACE=produbanmx-dev
DC=""
FQDN=""
DC_FILE_NAME=""

PSWD=$(
  sed '
    s/[[:space:]]\{1,\}/ /g; # turn sequences of spacing characters into one SPC
    s/[^[:print:]]//g; # remove non-printable characters
    s/^ //; s/ $//; # remove leading and trailing space
    q; # quit after first line' < fpass
)

function select_azone(){
	oc login -u x916511 -p $PSWD $POLL_SVC_ZONE -n $SNAMESPACE # https://api.cto2.paas.gsnetcloud.corp:8443 	
}

function clear_namespace(){
	oc login -u x916511 -p $PSWD $DEPLOY_ZONE
	DC_EXIST=$(oc get dc | grep $DC)
	if [ "$DC_EXIST" != "" ]
	then
		echo "!!!!!!!!!!!!!!!!! DC Exist...... will exec house"
		oc delete all -l app_name=$DC
	else
		echo "!!!!!!!!!!!!!!!!! DC doesnt exist"
	fi	 
}

function get_routename_host(){
	echo "===========>  in get route name from host"
	ROUTE_NAME=$(oc get routes | grep $ROUTE | awk {'print $1'})
	DC=$ROUTE_NAME
	echo $DC
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

function create_copy_yml(){
	echo ".......................................creating copy"
	echo "-------------------------------------- will login into $POLL_SVC_ZONE"
	oc login -u x916511 -p $PSWD $POLL_SVC_ZONE
	oc project $SNAMESPACE
	get_routename_host
	echo "The route name obtained is: ------------- $DC"
	DC_FILE_NAME=dc-$DC.yml
	echo "The dc filename is: ---------------- $DC_FILE_NAME "
	oc export dc $DC > $DC_FILE_NAME
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
	echo "................now we will create an app from the failed service"
	sleep 5

	#Login into BOAW
	oc login -u x916511 -p $PSWD $DEPLOY_ZONE
	clear_namespace	

#DEPLOY backup yml
	oc create -f $DC_FILE_NAME
	#Change route .- delete svc
	sleep 60
	oc expose dc $DC 
	#expose dc created
	sleep 60 
	oc expose svc $DC
	sleep 90
	 
}



function poll_ms(){
	COUNT_MIN=`expr $COUNT_MIN + 1`
	if [ "$COUNT_MIN" -le 1 ]
	then
	   echo "........ creating copy from polling aplication"
	   create_copy_yml
	fi


	echo "=================== >   Into polling service"
	RES_POLL=$(curl -k $ROUTE | grep "Application is not available")
	echo $RES_POLL
	if [ "$RES_POLL" != "" ]
	then
		echo "--------------RESTORE ENVIRONMENT"
		if [ "$COUNT_MIN" -eq 3 ]
		then
			echo "------------WILL CREATE NEW APP FROM FAILED SERVICE: $COUNT_MIN"
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
select_azone
while true; do
	poll_ms
	sleep 60
done

