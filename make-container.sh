#! /bin/bash

K8S_TAG=v1.13.2
KSONNET_VERSION=0.13.1
KSONNET_TAG=v${KSONNET_VERSION}
KUBEFLOW_TAG=v0.4.0
TERRAFORM_VERSION=0.11.11

if [ ! -f downloads/cfssl ]; then
    wget -q --show-progress --https-only --timestamping \
        https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
        https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
    mv cfssl_linux-amd64 downloads/cfssl
    mv cfssljson_linux-amd64 downloads/cfssljson
fi

if [ ! -f downloads/kubectl ]; then
    wget https://storage.googleapis.com/kubernetes-release/release/${K8S_TAG}/bin/linux/amd64/kubectl
    chmod +x kubectl
    mv kubectl downloads
fi

KSONNET_BASE=ks_${KSONNET_VERSION}_linux_amd64
KSONNET_DOWNLOAD=${KSONNET_BASE}.tar.gz
if [ ! -f downloads/ks ]; then
    wget https://github.com/ksonnet/ksonnet/releases/download/${KSONNET_TAG}/${KSONNET_DOWNLOAD}
    mv ${KSONNET_DOWNLOAD} downloads
    pushd downloads
    tar -xf ${KSONNET_DOWNLOAD}
    mv ${KSONNET_BASE}/ks .
    rm -rf ${KSONNET_BASE} ${KSONNET_DOWNLOAD}
    popd
fi

TERRAFORM_BASE=terraform_${TERRAFORM_VERSION}_linux_amd64
TERRAFORM_DOWNLOAD=${TERRAFORM_BASE}.zip
if [ ! -f downloads/terraform ]; then
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_DOWNLOAD}
    mv ${TERRAFORM_DOWNLOAD} downloads
    pushd downloads
    unzip ${TERRAFORM_DOWNLOAD}
    rm ${TERRAFORM_DOWNLOAD}
    popd
fi

export KUBEFLOW_SRC=downloads/kubeflow
if [ ! -d $KUBEFLOW_SRC ]; then
    mkdir $KUBEFLOW_SRC
    pushd $KUBEFLOW_SRC
    curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
    popd
fi
    
if [ ! -f downloads/aws-iam-authenticator ]; then
    wget https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
    chmod +x aws-iam-authenticator
    mv aws-iam-authenticator downloads
fi 

docker build -t k8s-client .
