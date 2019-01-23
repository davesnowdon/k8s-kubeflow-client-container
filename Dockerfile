FROM ubuntu:16.04

RUN apt-get update && \
    apt-get install -y \
        wget \
	openssh-client \
	python3 \
        python3-pip \
        python3-setuptools \
        groff \
        less \
	vim \
    && pip3 install --upgrade pip \
    && apt-get clean

RUN pip3 --no-cache-dir install --upgrade awscli

WORKDIR /usr/local/bin
COPY downloads/cfssl .
COPY downloads/cfssljson .
COPY downloads/kubectl .
COPY downloads/ks .
COPY downloads/terraform .
COPY downloads/aws-iam-authenticator .

WORKDIR /opt/kubeflow
COPY downloads/kubeflow .

WORKDIR /root
COPY providers.tf .
RUN /usr/local/bin/terraform init

RUN echo "export PATH=$PATH:/opt/kubeflow/scripts" >> /root/.bashrc

CMD ["/bin/bash"]