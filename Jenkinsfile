// Image info
def imageGroup = 'quangnghi'
def imageName = 'tictactoe'
def version = 'v1.0.0'
// Registry info

pipeline {
  agent { label 'jenkins-agent' }

  environment {
    //NODE_ENV = "$env.BRANCH_NAME"
    SCANNER_HOME=tool 'sonar-scanner'
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
        sh 'npm ci'
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
            -o trivy-fs-report.html \
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
                def dockerImage = docker.build("${imageGroup}/${imageName}:${version}", ".")
                //docker.withRegistry( docker_registry, dockerHubCredentialId ) {                       
				        //    dockerImage.push(version)
			          //}
                // Remove the image from the local docker
                //sh "docker rmi ${imageGroup}/${imageName}:${version} -f"
            }
        }
    }

    stage('Trivy Image Scan') {
      steps {
        script {
          def imageFullName = "${imageGroup}/${imageName}:${version}"
          echo "Scanning docker image ${imageFullName} with Trivy"
          sh """
            trivy image ${imageFullName} \
                --severity LOW,MEDIUM,HIGH \
                --exit-code 0 \
                --quiet \
                --format json -o trivy-image-MEDIUM-results.json


            trivy image ${imageFullName} \
                --severity CRITICAL \
                --exit-code 1 \
                --quiet \
                --format json -o trivy-image-CRITICAL-results.json
          """
          sh """
            trivy convert \
              --format template \
              --template "/usr/local/share/trivy/templates/html.tpl" \
              --output trivy-image-MEDIUM-results.html \
              trivy-image-MEDIUM-results.json


            trivy convert \
              --format template \
              --template "/usr/local/share/trivy/templates/html.tpl" \
              --output trivy-image-CRITICAL-results.html \
              trivy-image-CRITICAL-results.json
          """
        }
      }
      post {
          always {
            publishHTML([
                allowMissing: true, 
                alwaysLinkToLastBuild: true, 
                keepAll: true,
                reportDir: '.', 
                reportFiles: 'trivy-image-*.html', 
                reportName: 'Trivy HTML Reports'
            ])
        }
      }
    }

    stage('Run Docker Image Test') {
      steps {
        script {
          def imageFullName = "${imageGroup}/${imageName}:${version}"
          echo "Running docker image ${imageFullName}"
          sh "docker run -d --name tictactoe -p 80:80 ${imageFullName}"
        }
      }
    }
  }

  post {
    success {
      echo '✅ Build completed successfully!'
        }
    failure {
      echo '❌ Build failed.'
        }
    }
}