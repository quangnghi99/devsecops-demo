pipeline {
  agent jenkins-agent

  environment {
    NODE_ENV = 'production'
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'npm ci'
      }
    }

    stage('Build') {
      steps {
        sh 'npm run build'
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
