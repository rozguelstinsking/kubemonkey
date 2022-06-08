FROM ubuntu:22.04
USER root
RUN apt-get update && apt-get install apache2 -y && service apache2 start && apt-get install -y apt-transport-https && apt-get install wget -y && apt-get -y install curl && apt-get install net-tools && apt-get install haproxy -y && apt-get clean all
RUN mkdir /opt/psycho && chmod 755 /opt/psycho
RUN wget https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
RUN tar xvzf openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz && rm openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
RUN mkdir oc-tool
RUN mv openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit oc-tool && export PATH=$HOME/oc-tool:$PATH
COPY wild-monkey.sh /opt/psycho/wild-monkey.sh
#COPY fpass /opt/psycho/fpass
WORKDIR /opt/psycho 
CMD ["bash","wild-monkey.sh","&"]
