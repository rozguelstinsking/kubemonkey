FROM ubuntu:latest
USER root
RUN apt-get update && apt-get install -y apt-transport-https && apt-get -y install curl && apt-get install net-tools &&apt-get clean all
RUN mkdir /opt/psycho
RUN wget https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
RUN tar –xvf openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
RUN mkdir oc-tool
RUN mv openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit oc-tool && export PATH=$HOME/oc-tool:$PATH
COPY wild-monkey.sh /opt/psycho/wild-monkey.sh
COPY fpass /opt/psycho/fpass
WORKDIR /opt/psycho 
CMD ["bash","wild-monkey.sh","&"]
