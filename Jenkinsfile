pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Checkout'){
            steps {
                checkout scm
            }
        }
    }
}
