pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: maven
            image: maven:alpine
            command:
            - cat
            tty: true
        '''
    }
  }
  stages {
    container('maven'){
      stage('Build Artifact - Maven') {
        steps {
          sh 'mvn clean package -DskipTests=true'  
        }
      }
      stage('Test Artifact - Maven') {
        steps {
          sh 'mvn test'  
        }
       stage('Archive Artifact') {
        steps {
          archive 'target/*.jar' //so that they can be downloaded later
        }
      }
    }
  }
}
