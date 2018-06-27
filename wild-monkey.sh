!#/bin/bash

OUTPUT=""

oc login -u system -p admin https://127.0.0.1:8443

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

