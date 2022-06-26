#!/bin/sh

#k8s-deployment.sh

sed -i "s#replace#${IMAGETAG}#g" k8s_deployment_service.yaml
kubectl -n dev get deployment ${deploymentName} > /dev/null

if [[ $? -ne 0 ]]; then
    echo "deployment ${deploymentName} doesnt exist"
    kubectl -n dev apply -f k8s_deployment_service.yaml
else
    echo "deployment ${deploymentName} exist"
    echo "image name - ${IMAGETAG}"
    kubectl -n dev set image deploy ${deploymentName} ${containerName}=${IMAGETAG} --record=true
fi