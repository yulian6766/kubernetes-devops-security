#!/bin/sh

#integration-test.sh

sleep 5s

PORT=$(kubectl -n dev get svc $1 -o json | jq .spec.ports[].nodePort)

echo $PORT
echo $2:$PORT/$3

if [[ ! -z "$PORT" ]];
then

    response=$(curl -s $2:$PORT$3)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" $2:$PORT$3)

    if [[ "$response" == 100 ]];
        then
            echo "Increment Test Passed"
        else
            echo "Increment Test Failed"
            exit 1;
    fi;

    if [[ "$http_code" == 200 ]];
        then
            echo "HTTP Status Code Test Passed"
        else
            echo "HTTP Status code is not 200"
            exit 1;
    fi;

else
        echo "The Service does not have a NodePort"
        exit 1;
fi;