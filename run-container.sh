#! /bin/bash
# Want to be able to use kubectl proxy inside container and access proxied
# port from browser outside container
# port mappings
# 8001:8001 - k8s dashboard
# 8080:8080 - kubeflow UI (forwarded from port 80 on cluster)
docker run -it \
       -p 8001:8001 \
       -p 8080:8080 \
       -v $KUBEFLOW_DATA_DIR:/opt/data \
       -e AWS_ACCESS_KEY_ID=$AWS_KUBE_ACCESS_KEY_ID \
       -e AWS_SECRET_ACCESS_KEY=$AWS_KUBE_SECRET_ACCESS_KEY \
       -e AWS_DEFAULT_REGION=$AWS_KUBE_DEFAULT_REGION \
        k8s-client \
       /bin/bash
