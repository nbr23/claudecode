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
		stage('Sync github repo') {
			when { branch 'master' }
			steps {
					ghSync()
			}
		}
	}
}
