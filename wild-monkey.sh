#!/bin/bash
ENVIRON=""
PSWD=$(
  sed '
    s/[[:space:]]\{1,\}/ /g; # turn sequences of spacing characters into one SPC
    s/[^[:print:]]//g; # remove non-printable characters
    s/^ //; s/ $//; # remove leading and trailing space
    q; # quit after first line' < ./fpass
)


function select_azone(){
	AVAILABILITY_ZONE=$(echo $(( $RANDOM % 2 + 1 )))
	if [ "$AVAILABILITY_ZONE" -eq 1 ]
	then
	    oc login -u x916511 -p $PSWD https://api.cto1.paas.gsnetcloud.corp:8443  # https://api.cto2.paas.gsnetcloud.corp:8443
	else
	    oc login -u x916511 -p $PSWD https://api.cto2.paas.gsnetcloud.corp:8443
	fi
}

function get_name_spaces(){
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

PODS_FILE=""
function get_pods(){
	PODS_FILE=pods-$SNAMESPACE.txt
	# set into namespace and get pods
	# get_namespace
	oc project $SNAMESPACE
	oc get pods | awk '{print $1}' >  $PODS_FILE
}

function isDefault(){
        if [ "$SNAMESPACE" = "" ] || [ "$SNAMESPACE" = "default" ]
	then
	  return 0
	else
	  return 1
}

# this functionality needs to be executed under advanced privileges allowing delete a namespace
function delete_namespace(){
	echo "To enable this feature modify this script"
        echo "You need an user with elevated provileges"
	# hardcode for test into produbanmx-dev namespace, comment the herdcode var and uncomment dinamic value  # line=$(head -n 1 OUTPUT) 
	SNAMESPACE=$(head -n 1 NS_OUTPUT)
	ENVIRON=$(echo $SNAMESPACE | cut -f 2 -d '-')
	IS_DEFAULT=$(isDefault)
        if [ !"$IS_DEFAULT" ] || [ "$ENVIRON" = "dev" ] || [ "$ENVIRON" = "pre" ]
        then
          # SNAMESPACE=produbanmx-dev
	  echo $SNAMESPACE
	  # delete project rammdomly
	  oc delete project $SNAMESPACE
        else
          echo "Default namespace, never will be deleted"
          echo "To enable this feature modify this script"
          echo "You need an user with elevated provileges"
        fi	
}


## delete pods ---
function delete_pod(){
#1 select a namespace
	get_namespace
#2 get pods of namespace
	get_pods	
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
function delete_deployment(){
	get_namespace
	DCS_FILE=dcs-$SNAMESPACE.txt

	ENVIRON=$(echo $SNAMESPACE | cut -f 2 -d '-')
        
	if [ "$ENVIRON" = "dev" ] || [ "$ENVIRON" = "pre" ]
        then
	  oc get deploymentconfig | awk '{print $1}' > $DCS_FILE
	  # delete first line of file
	  echo "$(tail -n +2 $DCS_FILE)" > $DCS_FILE
	  # sort namespaces (projects) ramdomly and select one namespac
	  sort -R $DCS_FILE | head -n $(wc -l $DCS_FILE | awk '{print $1}') > DCS_OUTPUT
	  SDC=$(head -n 1 DCS_OUTPUT)
	  # create backupup oc deploymentconfig than will be deleted
	  oc export deploymentconfig $SDC > deploymentconfig-$SDC.yml
	  oc delete all -l app_name=$SDC
        else
	  echo "The environment selected was productive..... to delete deploymentconfig into this environment please modify the script"

	fi
}

SELECTEDEXPRESSION=0
function select_option(){
	echo "into select option"
	expressions=(pods namespaces deploymentconfigs) # (pods namespaces deploymentconfigs)
	SELECTEDEXPRESSION=${expressions[$RANDOM % ${#expressions[@]} ]}
	echo "$SELECTEDEXPRESSION"
	echo "exiting select option"
	echo $SELECTEDEXPRESSION
}

## Main config

while true; do
  echo "================================================================> we are into loop"
  select_azone
  get_name_spaces
  select_option
  echo "*************** The value will execute an action into ************"
  echo $SELECTEDEXPRESSION
	case $SELECTEDEXPRESSION in
	   pods)
	      echo "into pods selection"
	      delete_pod
	      ;;
	   namespaces)
	      echo "into namespaces selection"
              #TODO: Skip default and randomly select another namespace
	      delete_namespace 
	      ;;
	   deploymentconfigs)
	      echo "into deploymentconfigs selection"
	      delete_deployment
	      ;;
	   *)
	   echo "Selection executed"
	     ;;
	esac
      sleep 30
done 
