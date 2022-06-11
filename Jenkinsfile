podTemplate(
    label: 'slave', 
    cloud: 'kubernetes',
    serviceAccount: 'jenkins',
    containers: [
        containerTemplate(
            name: 'docker', 
            image: 'docker:dind', 
            ttyEnabled: true, 
            alwaysPullImage: true, 
            privileged: true,
            command: 'dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver=overlay'
        ),
        containerTemplate(
            name: 'maven',
            image: 'maven:alpine',
            ttyEnabled: true,
            command: 'cat'
        ),
        containerTemplate(
            name: 'kubectl', 
            image: 'lachlanevenson/k8s-kubectl:latest', 
            command: 'cat', 
            ttyEnabled: true
        )
    ],
   volumes: [
       emptyDirVolume(
           memory: false, 
           mountPath: '/var/lib/docker'
        )
    ]
) {
    node('slave') {

        //stage('Checkout code') {
        //    checkout scm
        //}
        
        container('maven') {
            stage('Build Artifact - Maven') {
                sh 'mvn clean package -DskipTests=true'
            }
            stage('Test Artifact - Maven JaCoCo') {
                try {
                    sh 'mvn test'
                } 
                finally {
                //    junit '**/target/surefire-reports/TEST-*.xml'
                }
            }
		
	    stage('Archive artifact') {
		archive 'target/*.jar' //so that they can be downloaded later
	    }
            //stage('Scann Code') {
            //    sh "mvn sonar:sonar -Dsonar.host.url=http://sonarqube-sonarqube:9000 -DskipTests=true -Dsonar.projectKey=$SERVICENAME -Dsonar.projectName=$SERVICENAME"
            //}
          
        }//maven

        /*container('docker') {
            stage('Create image') {
                docker.withRegistry("$REGISTRY_URL", "ecr:us-east-2:aws") {
                    image = docker.build("$IMAGETAG")
                    image.inside {
                        sh 'ls -alh'
                    }
                    image.push()
                }
            }
        }//docker

        container('kubectl') {
            stage('Deploy image') {
                sh "kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE"
                sh "kubectl get pods --namespace $NAMESPACE"
                sh "sed -i.bak 's#$PROJECT/$SERVICENAME:$IMAGEVERSION#$IMAGETAG#' ./k8s/dev/*.yaml"
                sh "kubectl --namespace=$NAMESPACE delete configmap $SERVICENAME-configmap"
                sh "kubectl --namespace=$NAMESPACE apply -f k8s/dev/configmap.yaml"
                sh "kubectl --namespace=$NAMESPACE apply -f k8s/dev/deployment.yaml"
                sh "kubectl --namespace=$NAMESPACE apply -f k8s/dev/service.yaml"
                sh "echo http://`kubectl --namespace=$NAMESPACE get service/$SERVICENAME --output=json jsonpath='{.status.loadBalancer.ingress[0].ip}'` > $SERVICENAME"
            }
        }*/

    }//node
}//podTemplate
// Prueba de compilación
