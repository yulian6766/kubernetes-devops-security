#!/bin/sh

#k8s-deployment-rollout-status.sh

sleep 40s

if [[ $(kubectl -n dev rollout status deploy $1 --timeout 5s) != *"successfully rolled out"* ]]; 
then     
	echo "Deployment $1 Rollout has Failed"
    kubectl -n dev rollout undo deploy $1
    exit 1;
else
	echo "Deployment $1 Rollout is Success"
fi