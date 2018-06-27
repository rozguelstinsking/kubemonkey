FROM ubuntu:latest
USER root
RUN apt-get update && apt-get install -y apt-transport-https && apt-get -y install curl && apt-get clean all
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl 
RUN apt-get clean all
RUN mkdir /opt/psycho
COPY wild-monkey.sh /opt/psycho/wild-monkey.sh
WORKDIR /opt/psycho 
CMD ["tail","-f","/dev/null"]
