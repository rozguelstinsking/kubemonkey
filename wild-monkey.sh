#!/bin/bash


log_in(){
	# oc login -u system -p admin https://127.0.0.1:8443
	echo "into login"
	oc login --token=OM4ouyUOa6wCd3h4iTGkjEVBrfbDFKCW_MXwvstaaL8
}

get_name_spaces(){
	echo "into get namespaces"
	# get projects and store into file
	oc get projects | awk '{print $1}' > namespaces.txt
	# delete first line of file
	echo "$(tail -n +2 namespaces.txt)" > namespaces.txt
	# sort namespaces (projects) ramdomly and select one namespac
	sort -R namespaces.txt | head -n $(wc -l namespaces.txt | awk '{print $1}') > NS_OUTPUT
	echo "exiting get namespaces"
}

SNAMESPACE=""
function get_namespace(){
	SNAMESPACE=$(head -n 1 NS_OUTPUT)
	echo $SNAMESPACE
	
}

PODS_FILE=pods-$SNAMESPACE.txt
get_pods(){
	# set into namespace and get pods
	get_namespace
	oc project $snamespace
	oc get pods | awk '{print $1}' >  $PODS_FILE
	return
}



delete_namespace(){
	# hardcode for test into produbanmx-dev namespace, comment the herdcode var and uncomment dinamic value  # line=$(head -n 1 OUTPUT) 
	snamespace=$(head -n 1 NS_OUTPUT)
	#snamespace=produbanmx-dev
	echo $snamespace
	# delete project rammdomly
	oc delete project $snamespace
	# set filename will contains pods
	return
}


## delete pods ---
delete_pod(){
	echo "into delete pods"
	# delete first line of file
	echo "$(tail -n +2 $PODS_FILE)" > $PODS_FILE
	# sort pods (projects) ramdomly and select one namespac
	sort -R $PODS_FILE | head -n $(wc -l $PODS_FILE | awk '{print $1}') > P_OUTPUT
	# select first line of random output
	spod=$(head -n 1 P_OUTPUT)
	echo $spod
	if [ "$spod" = "centos-tool-1-zh5jl" ]; then
	  echo "spod will not be deleted"
	else 
	  echo "spod will be deleted"
	fi
	# delete selected pod
	oc delete pod $spod
}

## delete deploymentconfigs
delete_deployment(){
	DCS_FILE=dcs-$snamespace.txt
	oc get deploymentconfig | awk '{print $1}' > $DCS_FILE
	oc export deploymentconfig agro-front
	# delete first line of file
	echo "$(tail -n +2 $DCS_FILE)" > $DCS_FILE
	# sort namespaces (projects) ramdomly and select one namespac
	sort -R $DCS_FILE | head -n $(wc -l $DCS_FILE | awk '{print $1}') > DCS_OUTPUT
	SDC=$(head -n 1 DCS_OUTPUT)
	# create backupup oc deploymentconfig than will be deleted
	oc export deploymentconfig $SDC > deploymentconfig-$SDC.yml
	oc delete deploymentconfig $SDC
	return 
}

selectedexpression=0
function select_option(){
	echo "into select option"

	expressions=(1 1 3)
	selectedexpression=${expressions[$RANDOM % ${#expressions[@]} ]}
	echo "$selectedexpression"
	echo "exiting select option"
	echo $selectedexpression
}

## Main config

echo "loging"
log_in

while true; do

	echo "--------------------------->  geting namespaces"
	get_name_spaces
	echo "will select option"
	select_option
	SELECTED_OPTION=$selectedexpression

	


	echo "executong case"
	echo "for selection "
	echo $SELECTED_OPTION

	if [ "$SELECTED_OPTION" = 1 ] 
	then
	  echo "pods selected"
	  delete_pod
	else if [ "$SELECTED_OPTION" = 2 ] 
	     then
		 echo "namespaces selected"
		 delete_namespace
	     else if [ "$SELECTED_OPTION" = 3 ] 
		  then 
		     echo "deploymentconfigs selected"
		     delete_deployment
		  fi
	     fi
	fi
		sleep 5
	echo "\n\n\n"
done

