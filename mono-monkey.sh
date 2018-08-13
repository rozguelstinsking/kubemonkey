#!/bin/bash

COUNT_MIN=0
MAKE_COPY=0
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
H_NAME=""
N_H_NAME=""

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

function reset_vars(){
	ROUTE=$N_H_NAME
	TMP_ZONE=$DEPLOY_ZONE
	DEPLOY_ZONE=$POLL_SVC_ZONE
	POLL_SVC_ZONE=$TMP_ZONE
}

function timer(){
	TOTAL_RESTORE_SECONDS=`expr  $1 - $2 `
	echo "######  Restore success in : $TOTAL_RESTORE_SECONDS seconds"
	TOTAL_RESTORE_MINUTES=`expr  $TOTAL_RESTORE_SECONDS \ 60 `
	SECS_FOR_MIN=`expr  $TOTAL_RESTORE_SECONDS % 60 `
	echo "######  Total mins: $TOTAL_RESTORE_MINUTES with $SECS_FOR_MIN"	
}


function check_restore(){
	RESPONSE=$(curl -k $N_H_NAME | grep "Application is not available")

	if [ "$RESPONSE" != "" ]
	then
	  echo " ***********   doesnt restored app   x_x "
	else   
	  echo ".....  *_*  The application was restored........"
	  reset_vars
	  echo true
	fi	
}

function clear_namespace(){
	oc login -u x916511 -p $PSWD $DEPLOY_ZONE
	DC_EXIST=$(oc get dc | grep $DC)
	if [ "$DC_EXIST" != "" ]
	then
		echo "!!!!!!!!!!!!!!!!! DC Exist...... will exec housekeeping"
		oc delete all -l app_name=$DC
	else
		echo "!!!!!!!!!!!!!!!!! DC doesnt exist"
	fi	 
}

function get_host_from_route(){
	H_NAME=$(oc get route $1 | awk {'print $2'} | tail -n +2)
	echo $H_NAME
}

function get_routename_host(){
	echo "===========>  in get route name from host"
	ROUTE_NAME=$(oc get routes | grep $ROUTE | awk {'print $1'})
	DC=$ROUTE_NAME
	echo $DC
} 

function redirect_proxy(){

	DNS1=$1
	DNS2=$2

	sudo cat /etc/httpd/conf.d/vhosts.conf
	EXP=s/$DNS1/$DNS2/
	SED_EXP="sed -i '$EXP' /etc/httpd/conf.d/vhosts.conf"
	sudo bash -c "$SED_EXP"

	sudo systemctl restart httpd	
}

function create_copy_yml(){
	MAKE_COPY=1;
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

function switch_service_zone(){
	echo "Into switchfunction"
	sudo sed "s/$1/$2/g" /etc/httpd/conf.d/vhosts.conf
	## IS NEEDED AN USER SYSTEM TO ALLOW RESTART OF PROXY
	sudo systemctl restart httpd
}

function create_new_app_from(){
	START_RESTORE_TIME=$(date +%s)
	echo "................now we will create an app from the failed service"
	sleep 5

	#Login into BOAW
	oc login -u x916511 -p $PSWD $DEPLOY_ZONE
	clear_namespace		
	sleep 60
#DEPLOY backup yml
	oc create -f $DC_FILE_NAME
	#Change route .- delete svc
	sleep 60
	oc expose dc $DC 
	#expose dc created
	sleep 10
	oc expose svc $DC
	sleep 90
        N_H_NAME=$(get_host_from_route $DC)
	
	echo $N_H_NAME
	VALU=true
	while "$VALU"; do
	  VALU=$(check_restore)
	  sleep 5
	done
	
	redirect_proxy "$H_NAME" "$N_H_NAME"
	END_RESTORE_TIME=$(date +%s)
	timer $END_RESTORE_TIME $START_RESTORE_TIME
}

function poll_ms(){
	H_NAME=$ROUTE
	COUNT_MIN=`expr $COUNT_MIN + 1`
	
	if [ "$MAKE_COPY" -lt 1 ]
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
		if [ "$COUNT_MIN" -ge 3 ]
		then
			echo "------------  WILL CREATE NEW APP BECAUSE SERVICE FAILED : $COUNT_MIN  TIMES"
			create_new_app_from
		else
			echo "!!!! Request Failed !!! ${COUNT_MIN} !!!!"
		fi  
	else
		echo "SITE IS RESPONDING"
     		COUNT_MIN=0
	fi
	
}


# MAIN CONFIG
select_azone
while true; do
	poll_ms
	sleep 30
done

