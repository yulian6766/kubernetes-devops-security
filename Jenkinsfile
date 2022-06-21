podTemplate(
    label: 'slave', 
    cloud: 'kubernetes-cloud',
    //serviceAccount: 'jenkins',
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
        ),

        containerTemplate(
            name: 'trivy',
            image: 'aquasec/trivy:0.29.0',
            command: 'cat', 
            ttyEnabled: true,
            args: 'infinity'
        ),
	
    ],
   volumes: [
       emptyDirVolume(
           memory: false, 
           mountPath: '/var/lib/docker'
        )
    ]
) {
    node('slave') {
	
	def PROJECT      = 'yulian6766'
	def SERVICENAME  = 'numeric-app'
	def REGISTRY_URL = "https://index.docker.io/v1/"
	def IMAGEVERSION = "beta"
	def IMAGETAG     = "$PROJECT/$SERVICENAME:$IMAGEVERSION${env.BUILD_NUMBER}"
	def NAMESPACE    = 'dev'
	    
        stage('Checkout code') {
            checkout scm
        }
        
        container('maven') {
            stage('Build Artifact - Maven') {
                sh 'mvn clean package -DskipTests=true'
            }
            stage('Test Artifact - Maven JaCoCo') {
                try {
                    sh 'mvn test'
                } 
                finally {
                    junit '**/target/surefire-reports/*.xml'
		            jacoco execPattern: 'target/jacoco.exec'
                }
            }
 	    
	        stage('Mutation Tests - PIT') {
      		    try {
			
            		sh "mvn org.pitest:pitest-maven:mutationCoverage"
		        }
          	
          	    finally {        		
          		    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml' 
      	        }
	        }
            
	        stage('SonarQube - SAST') {
		        withSonarQubeEnv('SonarQube') {
                	sh "mvn sonar:sonar -Dsonar.host.url=http://192.168.99.30:9000 -DskipTests=true -Dsonar.projectKey=$SERVICENAME -Dsonar.projectName=$SERVICENAME"
		        }
	            timeout(time: 2, unit: 'MINUTES') {
          		    script {
            			waitForQualityGate abortPipeline: true
          		    }
        	    }
            }
          
	        stage('Archive artifact') {
		        archive 'target/*.jar' //so that they can be downloaded later
	        }

            stage('Vulnerability Scan - Dependency Check ') {
                try {
                    sh "mvn dependency-check:check"
                }
                finally {
                    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                }
            }

        }//maven
    

        container('docker') {
            stage('Build And Push Image') {
                
                docker.withRegistry("$REGISTRY_URL", 'docker') {
                    image = docker.build("$IMAGETAG")
                    image.inside {
                    	sh 'ls -alh'
                	}
                image.push()
			    }
                
            }
        }//docker
	

        container('trivy') {   
            stage('Image Scan - Trivy ') {
                sh "trivy image -f json -o results.json $IMAGETAG"
                recordIssues(tools: [trivy(pattern: 'results.json')])
            }
        }//Trivy

        container('kubectl') {
            stage('Kubernetes - Prepare namespace') {
                sh "kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE"
                sh "kubectl get pods --namespace $NAMESPACE"
		        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
			        sh "kubectl -n $NAMESPACE create deploy node-app --image siddharth67/node-service:v1"
			        sh "kubectl -n $NAMESPACE expose deploy node-app --name node-service --port 5000"
		        }
		        sh "sed -i.bak 's#replace#$IMAGETAG#g' k8s_deployment_service.yaml"
	        }
            stage('Kubernetes Deployment') {
		        sh "kubectl -n $NAMESPACE apply -f k8s_deployment_service.yaml"
            }
        }//kubectl

        //post {
        //    always {
        //       junit 'target/surefire-reports/*.xml'
        //        jacoco execPattern: 'target/jacoco.exec'
        //        pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        //        dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        //    }

            // success {

            // }

            // failure {

            // }
        //}//post

    }//node
}//podTemplate
// Prueba de compilación
