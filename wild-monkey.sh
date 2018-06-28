!#/bin/bash

OUTPUT=""

#oc login -u system -p admin https://127.0.0.1:8443
oc login --token=WUSeEXKA-uyxda9lD-7l11vJXs9ID2ivchaXLB6W3Ew https://api.cto2.paas.gsnetcloud.corp:8443
oc project produbanmx-pre

# get projects and store into file
oc get projects | awk '{print $1}' > namespaces.txt

# delete first line of file
echo "$(tail -n +2 namespaces.txt)" > namespaces.txt

# sort namespaces (projects) ramdomly and select one namespac
sort -R namespaces.txt | head -n 5 > OUTPUT
line=$(head -n 1 OUTPUT)
echo $line

# delete project rammdomly
# oc delete project $line

# set filename will contains pods
PODS_FILE=pods-$line.txt

# select namespace and get pods
oc project $line
oc get pods | awk '{print $1}' >  $PODS_FILE

OPTION=awk -v min=5 -v max=10 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'
#oc login -u system -p admin https://127.0.0.1:8443
oc login --token=


get_namespaces(){
	# get projects and store into file
	oc get projects | awk '{print $1}' > namespaces.txt
	# delete first line of file
	echo "$(tail -n +2 namespaces.txt)" > namespaces.txt
	# sort namespaces (projects) ramdomly and select one namespac
	sort -R namespaces.txt | head -n $(wc -l namespaces.txt | awk '{print $1}') > NS_OUTPUT
}


delete_namespace(){
	
	# hardcode for test into produbanmx-dev namespace, comment the herdcode var and uncomment dinamic value  # line=$(head -n 1 OUTPUT) 
	# snamespace=$(head -n 1 NS_OUTPUT)
	snamespace=produbanmx-dev
	echo $snamespace
	# delete project rammdomly
	# oc delete project $snamespace
	# set filename will contains pods
	PODS_FILE=pods-$snamespace.txt
	# set into namespace and get pods
	oc project $snamespace
	oc get pods | awk '{print $1}' >  $PODS_FILE
}


## delete pods ---
delete_pod(){
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

# select an option to be fired
#S_OPTION=/bin/sh -c "awk -v min=1 -v max=3 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'"

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
}

## Main config
get_namespaces()

case $SELECTION in
   pods)
      delete_pod()
      ;;
   namespaces)
      delete_namespace() 
      ;;
   deploymentconfigs)
      delete_deployment() 
      ;;
   *)
   echo "Selection executed"
     ;;
esac

