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
            //image: 'lachlanevenson/k8s-kubectl:latest', 
            image: 'juntezhang/kubectl-jq:latest', 
            command: 'cat', 
            ttyEnabled: true
        ),

        containerTemplate(
            name: 'trivy',
            image: 'aquasec/trivy:latest',
            command: 'cat', 
            ttyEnabled: true,
        ),

        containerTemplate(
            name: 'confest',
            image: 'openpolicyagent/conftest:latest',
            command: 'cat', 
            ttyEnabled: true,
        ),

        containerTemplate(
            name: 'kubesec',
            image: 'dwdraju/alpine-curl-jq:latest',
            command: 'cat', 
            ttyEnabled: true,
        ),

        containerTemplate(
            name: 'owasp-zap',
            image: 'owasp/zap2docker-weekly:latest',
            command: 'cat', 
            ttyEnabled: true,
        ),
	
    ],
   volumes: [
       emptyDirVolume(
           memory: false, 
           mountPath: '/var/lib/docker'
        ),
        hostPathVolume(
            hostPath : '$(pwd)', 
            mountPath: '/zap/wrk/'
        )
    ]
) {
    node('slave') {
	
	def PROJECT         = 'yulian6766'
	def SERVICENAME     = 'numeric-app'
	def REGISTRY_URL    = "https://index.docker.io/v1/"
	def IMAGEVERSION    = "beta"
	def IMAGETAG        = "$PROJECT/$SERVICENAME:$IMAGEVERSION${env.BUILD_NUMBER}"
	def NAMESPACE       = 'dev'

    def deploymentName  = "devsecops"
    def containerName   = "devsecops-container"
    def serviceName     = "devsecops-svc" //"node-service"
    def imageName       = "yulian6766/numeric-app:$IMAGETAG"
    def applicationURL  = "http://192.168.99.32"
    def applicationURI  = "/increment/99"
    def dockerImageName = ""
    def PORT            = ""
	    
        stage('Checkout code') {
            checkout scm
        }//SCM
        
        container('maven') {
            stage('Build Artifact - Maven') {
                sh 'mvn clean package -DskipTests=true'
            }//Build

            stage('Test Artifact - Maven JaCoCo') {
                try {
                    sh 'mvn test'
                } 
                finally {
                    junit '**/target/surefire-reports/*.xml'
		            jacoco execPattern: 'target/jacoco.exec'
                }
            }//JaCoCo
 	    
	        stage('Mutation Tests - PIT') {
      		    try {
			
            		sh "mvn org.pitest:pitest-maven:mutationCoverage"
		        }
          	
          	    finally {        		
          		    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml' 
      	        }
	        }//PIT
            
	        stage('SonarQube - SAST') {
		        withSonarQubeEnv('SonarQube') {
                	sh "mvn sonar:sonar -Dsonar.host.url=http://sonar-service.sonar.svc.cluster.local:9000/ -DskipTests=true -Dsonar.projectKey=$SERVICENAME -Dsonar.projectName=$SERVICENAME"
		        }
	            timeout(time: 2, unit: 'MINUTES') {
          		    script {
            			waitForQualityGate abortPipeline: true
          		    }
        	    }
            }//SAST
          
	        //stage('Archive artifact') {
		    //    archive 'target/*.jar' //so that they can be downloaded later
	        //}//archive artifact

        }//maven

        stage('Docker Vuln Scan'){
            parallel(
                "Dependency Check": {
                    container('maven') {
                        try {
                            sh "mvn dependency-check:check"
                        }
                        finally {
                            dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                        }
                    }//maven
                },//Dep Check
                
                "OPA Conftest": {
                    container('confest') {
                        sh 'conftest test --policy dockerfile-security.rego Dockerfile'
                    }//confest
                },//Opa Conf
                
                "Trivy Scan": {
                    container('trivy') {  
                        sh '''dockerImageName=$(awk 'NR==2 {print $2}' Dockerfile)
                            trivy image -f json -o docker_results.json $dockerImageName'''
                        //recordIssues (id: 'trivy-docker', name: 'trivy-docker', tools: [trivy(pattern: 'docker_results.json')])
                    }//Trivy
                }//Trivy Scan

            )//Parallel
        }



        container('docker') {
            stage('Build And Push Image') {
                
                docker.withRegistry("$REGISTRY_URL", 'docker') {
                    image = docker.build("$IMAGETAG")
                    image.inside {
                    	sh 'ls -alh'
                	}
                image.push()
			    }//docker withRegistry
                
            }//Build And Push Image
        }//docker

        stage('K8s Vuln Check'){
            parallel(
                "OPA Scan": {
                    container('confest') {
                        sh 'conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
                    }//Confest
                }, //OPA Scan

                "Kubesec Scan": {
                    container('kubesec'){
                        sh 'sh kubesec-scan.sh'
                    }//Kubesec
                }, //Kubesec Scan

                "Trivy Scan": {
                    container('trivy') {   
                        sh "trivy image -f json -o k8s_results.json $IMAGETAG"
                        sh "ls -ltr"
                        recordIssues (id: 'trivy-k8s', name: 'trivy-k8s', tools: [trivy(pattern: '*_results.json')])
                    }//Trivy
                }//Trivy Scan
            )//Parallel
        }//K8s Vuln Check

        container('kubectl') {
            
                stage('Kubernetes - Prepare namespace') {
                    sh "kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE"
                    sh "kubectl get pods --namespace $NAMESPACE"
                    env.PORT = sh "kubectl -n default get svc $serviceName -o json | jq .spec.ports[].nodePort)"
		        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
			        sh "kubectl -n $NAMESPACE create deploy node-app --image siddharth67/node-service:v1"
			        sh "kubectl -n $NAMESPACE expose deploy node-app --name node-service --port 5000"
		        }
		
                parallel(
                    "Deployment": {
                        sh "sh k8s-deployment.sh $IMAGETAG $deploymentName $containerName"
                    },//Deployment
                    "Rollout Status": {
                        sh "sh k8s-deployment-rollout-status.sh $deploymentName"
                    }//Rollout
                )//Parallel
            }//K8S Deployment - DEV

            stage('Integration Tests - DEV') {
                timeout(time: 2, unit: 'MINUTES') {
          		    script {
                        try {
                            sh "bash integration-test.sh $serviceName $applicationURL $applicationURI"
                        } catch (e) {
                            sh "kubectl -n dev rollout undo deploy $deploymentName"
                            throw e
                        }
                    }
        	    }
            }
        }//kubectl

        container('owasp-zap') {
            stage('OWASP ZAP - DAST') {
                sh "bash zap.sh $serviceName $PORT"
            }
        }//owasp-zap

    }//node

}//podTemplate
