// engineerbetter/iac-example-ci:13-record-versions
def ciImage = 'engineerbetter/iac-example-ci@sha256:fb41d970f0bb20cd71ba855616910c4d0920cadb2fcc636086224ce61bf1936e'

pipeline {
  agent {
    kubernetes {
      yaml """
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: iac
            image: ${ciImage}
            command:
            - cat
            tty: true
        """.stripIndent()
      defaultContainer 'iac'
    }
  }

  environment {
    BOOTSTRAP_AWS_REGION = credentials 'BOOTSTRAP_AWS_REGION'
    BOOTSTRAP_BUCKET_NAME = credentials 'BOOTSTRAP_BUCKET_NAME'
    BOOTSTRAP_DYNAMO_TABLE_NAME = credentials 'BOOTSTRAP_DYNAMO_TABLE_NAME'
  }

  stages {
    stage('Terraform bootstrap') {
      environment {
        AWS_ACCESS_KEY_ID = credentials 'AWS_ACCESS_KEY_ID'
        AWS_SECRET_ACCESS_KEY = credentials 'AWS_SECRET_ACCESS_KEY'
      }

      steps {
        sh 'make terraform-bootstrap'
      }
    }

    stage('Terraform init') {
      environment {
        AWS_ACCESS_KEY_ID = credentials 'AWS_ACCESS_KEY_ID'
        AWS_SECRET_ACCESS_KEY = credentials 'AWS_SECRET_ACCESS_KEY'
      }

      steps {
        sh 'make terraform-init'
      }
    }

    stage('Static checks') {
      parallel {
        stage('Validate terraform') {
          steps {
            sh 'make terraform-validate'
          }
        }

        stage('Lint terraform') {
          steps {
            sh 'make terraform-lint'
          }
        }

        stage('Check format') {
          steps {
            sh 'make terraform-fmt-check'
          }
        }

        stage('Policy test') {
          steps {
            sh 'make policy-test'
          }
        }

        stage('Snyk: test terraform') {
          environment {
            SNYK_TOKEN = credentials 'SNYK_TOKEN'
          }

          steps {
            retry(3) {
              sh 'make snyk-test-terraform'
            }
          }
        }

        stage('Snyk: test manifest') {
          environment {
            SNYK_TOKEN = credentials 'SNYK_TOKEN'
            IGNORE_SNYK_TEST_DEPLOYMENTS_FAILURE = 'true'
          }

          steps {
            retry(3) {
              sh 'make snyk-test-deployments'
            }
          }
        }
      }
    }

    stage('Deploy cluster') {
      environment {
        AWS_ACCESS_KEY_ID = credentials 'AWS_ACCESS_KEY_ID'
        AWS_SECRET_ACCESS_KEY = credentials 'AWS_SECRET_ACCESS_KEY'
        SNYK_TOKEN = credentials 'SNYK_TOKEN'
        IGNORE_SNYK_TEST_PLAN_FAILURE = 'true'
      }

      steps {
        sh 'make deploy-cluster'
      }
    }

    stage('Deploy sock shop') {
      environment {
        AWS_ACCESS_KEY_ID = credentials 'AWS_ACCESS_KEY_ID'
        AWS_SECRET_ACCESS_KEY = credentials 'AWS_SECRET_ACCESS_KEY'
      }

      steps {
        sh 'make fetch-cluster-config'
        sh 'make deploy-sock-shop'
      }
    }

    stage('Integration tests') {
      environment {
        AWS_ACCESS_KEY_ID = credentials 'AWS_ACCESS_KEY_ID'
        AWS_SECRET_ACCESS_KEY = credentials 'AWS_SECRET_ACCESS_KEY'
      }

      steps {
        sh 'make fetch-cluster-config'
        sh 'make integration-test'
      }
    }
  }

  post {
    always {
      cleanWs()
    }

    failure {
      slackSend(
        message: "Deploy failed: <${env.BUILD_URL}|${env.JOB_NAME}#${env.BUILD_NUMBER}>",
        color: 'danger',
        username: 'The Butler',
        tokenCredentialId: 'SLACK_WEBHOOK_CREDENTIAL',
        baseUrl: 'https://hooks.slack.com/services/',
        channel: env.SLACK_CHANNEL
      )
    }
  }
}