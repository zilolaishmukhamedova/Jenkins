pipeline {
    agent any
    tools {
        terraform 'terraform'
    }
    stages {
        stage('Git Init') {
            steps {
                git credentialsId: 'gogreen-project-key', url: 'https://github.com/GoGreenProjectT3/Team3.git'
            }
        }
        stage('Terraform Init') {
            steps {
                sh 'terraform init -no-color'
            }
        }
        stage('Terraform Apply/Destroy') {
            steps {
                sh 'terraform ${action} --auto-approve -no-color'
            }
        }
    }
}