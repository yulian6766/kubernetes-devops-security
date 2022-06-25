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
            image: 'aquasec/trivy:latest',
            command: 'cat', 
            ttyEnabled: true,
            //args: 'infinity'
        ),

        containerTemplate(
            name: 'confest',
            image: 'openpolicyagent/conftest:latest',
            command: 'cat', 
            ttyEnabled: true,
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
	
	def PROJECT         = 'yulian6766'
	def SERVICENAME     = 'numeric-app'
	def REGISTRY_URL    = "https://index.docker.io/v1/"
	def IMAGEVERSION    = "beta"
	def IMAGETAG        = "$PROJECT/$SERVICENAME:$IMAGEVERSION${env.BUILD_NUMBER}"
	def NAMESPACE       = 'dev'

    def deploymentName  = "devsecops"
    def containerName   = "devsecops-container"
    def serviceName     = "devsecops-svc"
    def imageName       = "yulian6766/numeric-app:${GIT_COMMIT}"
    def applicationURL  = "http://192.168.99.32:31363/"
    def applicationURI  = "/increment/99"
	    
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
    
        container('confest') {
            stage('OPA Conftest - Dockerfile') {
                sh 'conftest test --policy dockerfile-security.rego Dockerfile'
            }
        }

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
                //sh "trivy image -f json -o results.json $IMAGETAG --severity CRITICAL --exit-code 1"
                recordIssues(tools: [trivy(pattern: 'results.json')])
            }
        }//Trivy

        container('confest') {
            stage('OPA Conftest - K8s') {
                sh 'conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
            }
        }

        container('kubectl') {
            stage('K8S Deployment - DEV') {
                parallel(
                    "Deployment": {
                        //withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "bash k8s-deployment.sh"
                        //}
                    },
                    "Rollout Status": {
                        //withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "bash k8s-deployment-rollout-status.sh"
                        //}
                    }
                )
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
