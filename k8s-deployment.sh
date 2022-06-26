#!/bin/sh

#k8s-deployment.sh

sed -i "s#replace#$1#g" k8s_deployment_service.yaml
kubectl -n dev get deployment $2 > /dev/null

if [[ $? -ne 0 ]]; then
    echo "deployment $2 doesnt exist"
    kubectl -n dev apply -f k8s_deployment_service.yaml
else
    echo "deployment $2 exist"
    echo "image name - $1"
    kubectl -n dev set image deploy $2 $3=$2 --record=true
fi