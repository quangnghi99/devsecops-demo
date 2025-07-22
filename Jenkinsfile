pipeline {
  agent { label 'jenkins-agent' }

  environment {
    NODE_ENV = 'production'
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

    stage('Debug') {
      steps {
        sh '''
          pwd
          ls -la
        '''
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'npm ci'
      }
    }

    stage('Lint') {
      steps {
        sh 'npm run lint'
      }
    }

    stage('Test') {
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
