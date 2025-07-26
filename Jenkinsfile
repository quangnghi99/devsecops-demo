// Library for Jenkinsfile
@Library('jenkins-shared-lib') _

// Image info
def imageGroup = 'quangnghi'
def imageName = 'tictactoe'
def version = "${env.BRANCH_NAME}-v1.${env.BUILD_NUMBER}"
// Registry info
def dockerHubCredentialId = 'dockerhub'
def docker_registry = 'https://index.docker.io/v1/'

pipeline {
  agent { label 'jenkins-agent' }

  environment {
    //NODE_ENV = "$env.BRANCH_NAME"
    SCANNER_HOME = tool 'sonar-scanner'
  }

  options {
    skipStagesAfterUnstable()
    timestamps()
  }


  stages {
    stage('Clean Workspace') {
      steps {
        cleanWs()
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage("Sonarqube Analysis "){
      steps{
        withSonarQubeEnv('sonar-server') {
            sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=TicTacToe \
            -Dsonar.projectKey=TicTacToe '''
        }
      }
    }

    stage("Quality Gate"){
      steps {
        script {
          waitForQualityGate abortPipeline: false
        }
      } 
    }

    stage('Install Dependencies') {
      steps {
        sh 'npm install'
      }
    }

    stage('OWASP FS SCAN') {
      steps {
        dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', nvdCredentialsId: 'NVD', odcInstallation: 'DP'
        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
      }
    }

    stage('Trivy FileSystem Scan') {
      steps {
        sh '''
          trivy fs --scanners vuln,secret,misconfig \
            --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
            -o trivy-fs-results.html \
            .
        '''
      }
    }

    stage('Static Code Analysis') {
      steps {
        sh 'npm run lint'
      }
    }

    stage('Unit Test') {
      steps {
        sh 'npm test'
      }
    }

    stage('Build docker image') {
      steps {
        echo "Building docker image..."
        script {
          docker.build("${imageGroup}/${imageName}:${version}", ".")
        }
      }
    }

    stage('Trivy Image Scan') {
      steps {
        script {
          def dockerImage = "${imageGroup}/${imageName}:${version}"
          def failOnCritical = false
          def output = "trivy-image-results"
          echo "Scanning docker image ${dockerImage} with Trivy"
          trivyScan.scanImage(dockerImage, "${output}.json", failOnCritical)
          trivyScan.convertJsonToHtml("${output}.json", "${output}.html")
        }
      }
      post {
        always {
          script {
            trivyScan.publishTrivyReport([
              reportName: 'Trivy Results',
              reportFiles: 'trivy-*.html',
              reportDir: '.',
            ])
          }
        }
      }
    }
    
    stage('Push docker image') {
      steps {
        script {
          def dockerImage = "${imageGroup}/${imageName}:${version}"
          echo "Push docker image ${dockerImage} to registry..."
          docker.withRegistry( docker_registry, dockerHubCredentialId ) {                       
			      sh "docker push ${dockerImage}"
          }
          // Remove the image from the local docker
          sh "docker rmi ${dockerImage} -f"
		    }
      }
    }
  }

  post {
    success {
        script {
          def buildUrl = env.BUILD_URL + "console"
          def message = """
            ✅ *${env.JOB_NAME}* build #${env.BUILD_NUMBER} success.
            [Console Output](${buildUrl})
          """.stripIndent()
          sendTelegramMessage(message)
        }
      
    }
    failure {
        script {
          def buildUrl = env.BUILD_URL + "console"
          def message = """
            ❌ *${env.JOB_NAME}* build #${env.BUILD_NUMBER} failure.
            [Console Output](${buildUrl})
          """.stripIndent()
          sendTelegramMessage(message)
        }
      
    }
    unstable {

        script {
          sendTelegramMessage("⚠️ *${env.JOB_NAME}* build #${env.BUILD_NUMBER} unstable.")
        }
      
    }
  }
}