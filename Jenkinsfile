// Image info
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

    stage('Install Dependencies') {
      steps {
        sh 'npm ci'
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

    stage('Build') {
      steps {
        sh 'npm run build'
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