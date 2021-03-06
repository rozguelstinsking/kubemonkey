#!/bin/bash
ENVIRON=""
COUNT_MIN=0

#PSWD=$(
#  sed '
#    s/[[:space:]]\{1,\}/ /g; # turn sequences of spacing characters into one SPC
#    s/[^[:print:]]//g; # remove non-printable characters
#    s/^ //; s/ $//; # remove leading and trailing space
#    q; # quit after first line' < ./fpass
#)

# parametrized
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
function select_namespace(){
	SNAMESPACE=$(head -n 1 NS_OUTPUT)
	echo $SNAMESPACE
}

PODS_FILE=""
function get_pods(){
	PODS_FILE=pods-$SNAMESPACE.txt
	# set into namespace and get pods
	# select_namespace
	oc project $SNAMESPACE
	oc get pods | awk '{print $1}' >  $PODS_FILE
}

function isDefault(){
        if [ "$SNAMESPACE" = "" ] || [ "$SNAMESPACE" = "default" ]
	then
	  return 0
	else
	  return 1
	fi
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
          echo "          !!!!!!!!!!!!! Default namespace, never will be deleted  !!!!!!!!!!!!!!!!"
	  echo "        

                    A new namespace will be selected"
	  SNAMESPACE=$(head -n 1 NS_OUTPUT)
          echo "                  To enable this feature modify this script"
          echo "                  You need an user with elevated provileges"
        fi	
}


## delete pods ---
function delete_pod(){
#1 select a namespace
	select_namespace # Select namespace from availability zone
#2 get pods of namespace
	get_pods # Get pods from selected namespace above
	echo "into delete pods"
	# delete first line of file
	echo "$(tail -n +2 $PODS_FILE)" > $PODS_FILE  # PODS_FILE env_var comes from get_pods
	# sort pods (projects) ramdomly and select one namespac
	sort -R $PODS_FILE | head -n $(wc -l $PODS_FILE | awk '{print $1}') > P_OUTPUT
	# select first line of random output
	SPOD=$(head -n 1 P_OUTPUT)
	echo $SPOD
	if [ "$SPOD" = "centos-tool-1-zh5jl" ]; then
	  echo "SPOD will not be deleted"
	else 
	  echo "SPOD will be deleted"
	fi
	# TODO create previous state of namespace.
	oc export $SPOD > $SNAMESPACE-pod-$SPOD.yml # Create backup of pod
	# delete selected pod
	oc delete pod $SPOD
}

## delete deploymentconfigs
function delete_deployment(){
	select_namespace # Will select namespace every time calling function and assign new value to SNAMESPACE env_var  
	DCS_FILE=dcs-$SNAMESPACE.txt
	ENVIRON=$(echo $SNAMESPACE | cut -f 2 -d '-')
	if [ !"$IS_DEFAULT" ] || [ "$ENVIRON" = "dev" ] || [ "$ENVIRON" = "pre" ]
        then
	  oc get deploymentconfig | awk '{print $1}' > $DCS_FILE
	  # delete first line of file
	  echo "$(tail -n +2 $DCS_FILE)" > $DCS_FILE
	  # sort namespaces (projects) ramdomly and select one namespac
	  sort -R $DCS_FILE | head -n $(wc -l $DCS_FILE | awk '{print $1}') > DCS_OUTPUT
	  SDC=$(head -n 1 DCS_OUTPUT)
	  # create backupup oc deploymentconfig than will be deleted
	  oc export deploymentconfig $SDC > $SNAMESPACE-dc-$SDC.yml
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

function restore_env_verifier(){
	# Search into previous state of namespace and compare with actual scan of namespace state
	# if pods, dc, svc and routes have the same config yml files into list and backup files
	# Restore will be ready and time of difference will be the bound cleared time
	echo "Restore_env_verifier_"
}

function backup_env(){
	BACKUP_DIR="../backups/backup-$SNAMESPACE/"
	if [ ! -d "$BACKUP_DIR" ];
	then
		echo "creating backup dir"
		mkdir $BACKUP_DIR
	fi
	oc export dc,svc,route --selector=app_name=$SNAMESPACE -n $SNAMESPACE > $BACKUP_DIR-$SNAMESPACE.yml
}

function clear_namespace(){
	echo "All objects will be deleted into '$SNAMESPACE'"
	# oc get pods,dc,svc,route
	oc project $SNAMESPACE
	oc get dc,svc,route | awk '{print $1}' > RES_OUTPUT
	while read p; do
		echo "into while" 	
		  echo $p
		if [ "$p" = "" ] || ["$p" = "NAME"]
		then
 		  echo "Was space blank or NAME "
		else	
		  oc delete $p
		fi
	done < RES_OUTPUT 
	echo "Finished"
}


function get_routes_ms(){
	echo "Into get routes"
	IFS='-' tokens=( $SPOD )
	TWORDS=$(echo ${#tokens[@]})
	COUNT_TO=$(expr  $TWORDS - 2 )
	echo "TOTAL WORDS: '$COUNT_TO'"
	for ((i=0; i < "$COUNT_TO" ; i++ ))
	do
	echo ${tokens[i]}
	if [ "$i" -le 0 ]
	then
	ROUTE_NAME=${tokens[i]}
	else
	ROUTE_NAME="$ROUTE_NAME' '${tokens[i]}"
	fi
	echo $ROUTE_NAME
	done
	echo $ROUTE_NAME | sed "s/' '/-/g"
	# oc delete route $ROUTE_NAME
}

## Main config

while true; do
  echo " <=============================   we are into loop   ===================================> "
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
	   echo "********======================    End of execution   ===========================**********"
	     ;;
	esac
      sleep 30
done 
