#!/usr/bin/env groovy

pipeline {
  agent { label 'master' }
  environment {
    DEVELOPER_DIR = '/Xcode/9.2/Xcode.app/Contents/Developer'

    SLACK_COLOR_DANGER  = '#E01563'
    SLACK_COLOR_INFO    = '#6ECADC'
    SLACK_COLOR_WARNING = '#FFC300'
    SLACK_COLOR_GOOD    = '#3EB991'
    PROJECT_NAME = 'Calabash.iOS'
  }
  options {
    disableConcurrentBuilds()
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  stages {
    stage('announce') {
      steps {
        slackSend(color: "${env.SLACK_COLOR_INFO}",
            message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Started* (<${env.BUILD_URL}|Open>)")
      }
    }
    stage('prepare') {
      parallel {
        stage('calabash-cucumber bundle') {
          steps {
            sh 'cd calabash-cucumber; bundle update'
            sh 'cd calabash-cucumber/test/cucumber; bundle update'
          }
        }
      }
    }
    stage('rspec') {
      steps {
        sh 'bin/ci/jenkins/rspec.sh'
      }
    }
    stage('cli') {
      steps {
        sh 'bin/ci/cli.sh'
      }
    }
    stage('cucumber') {
      steps {
        sh 'cd calabash-cucumber/test/cucumber; ./run.sh'
      }
    }
  }
  post {
    always {
      junit 'calabash-cucumber/spec/reports/*.xml'
    }

    aborted {
      echo "Sending 'aborted' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_WARNING}",
               message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Aborted* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }

    failure {
      echo "Sending 'failed' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_DANGER}",
               message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Failed* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }

    success {
      echo "Sending 'success' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_GOOD}",
               message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Success* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }
  }
}
