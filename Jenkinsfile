pipeline {

    agent any

    parameters {

        choice(
            name: 'ACTION',
            choices: ['BUILD', 'DEPLOY'],
            description: 'Pipeline action'
        )

        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image tag'
        )

        choice(
            name: 'ENVIRONMENT',
            choices: ['dev','staging','prod'],
            description: 'Deployment environment'
        )
    }

    environment {

        /* ================= GLOBAL ================= */

        IMAGE_NAME        = "${env.IMAGE_NAME}"
        CONTAINER_NAME    = "${env.CONTAINER_NAME ?: IMAGE_NAME + '-staging'}"
        STAGING_PORT      = "${env.STAGING_PORT ?: '8080'}"

        /* ================= HARBOR ================= */

        HARBOR_REGISTRY   = "${env.HARBOR_REGISTRY}"
        HARBOR_PROJECT    = "${env.HARBOR_PROJECT}"

        /* ================= TEMPLATE ================= */

        TEMPLATE_REPO   = "${env.TEMPLATE_REPO}"
        TEMPLATE_BRANCH = "${env.TEMPLATE_BRANCH ?: 'main'}"

        /* ================= GITOPS ================= */

        GITOPS_REPO       = "${env.GITOPS_REPO}"
        GITOPS_PATH       = "${env.GITOPS_PATH}"

        /* ================= SOURCE ================= */

        SOURCE_REPO       = "${env.SOURCE_REPO}"
        SOURCE_BRANCH     = "${env.SOURCE_BRANCH ?: 'main'}"
    }

    stages {

    /* ======================= CI ========================== */

        stage('Checkout Source') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {
                git branch: "${SOURCE_BRANCH}",
                    url: "https://${SOURCE_REPO}"
            }
        }

    /* stage('Skip Bot Commit') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {
                script {

                    def author = sh(
                        script: "git log -1 --pretty=%an",
                        returnStdout: true
                    ).trim()

                    echo "Commit author: ${author}"

                    if (author == "Jenkins CI") {
                        currentBuild.result = 'NOT_BUILT'
                        error("Build triggered by Jenkins bot, skipping pipeline")
                    }
                }
            }
        }*/

        stage('Verify Variables') {
            steps {
                script {

                    def required = [
                        'IMAGE_NAME',
                        'HARBOR_REGISTRY',
                        'HARBOR_PROJECT',
                        'GITOPS_REPO',
                        'SOURCE_REPO'
                    ]

                    for (var in required) {
                        if (!env."${var}") {
                            error "Missing variable: ${var}"
                        }
                    }

                }
            }
        }

        stage('Build') {
            when { expression { params.ACTION == 'BUILD' } }
            steps {

                sh '''
                if [ -f mvnw ]; then
                  chmod +x mvnw
                  ./mvnw clean package -DskipTests
                else
                  mvn clean package -DskipTests
                fi
                '''

            }
        }

        stage('Unit Test & Quality Checks') {

            when { expression { params.ACTION == 'BUILD' } }

            parallel {

                stage('Unit Tests') {

                    /*steps {
                        sh '''
                        if [ -f mvnw ]; then
                        ./mvnw test
                        else
                        mvn test
                        fi
                        '''
                    }*/

                    steps {
                        sh 'echo "unit tests"'
                    }

                }

                stage('SonarQube Analysis') {

                    /*
                    steps {

                        withSonarQubeEnv('SonarQubeServer') {

                            withCredentials([
                                string(
                                    credentialsId: 'jenkinstoken',
                                    variable: 'SONAR_TOKEN'
                                )
                            ]) {

                                sh '''
                                if [ -f mvnw ]; then
                                  ./mvnw sonar:sonar -Dsonar.login=$SONAR_TOKEN
                                else
                                  mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN
                                fi
                                '''

                            }

                        }

                    }
                    */

                    steps {
                        sh 'echo "sonarqube analysis"'
                    }

                }

            }

        }

        stage('Checkout Template') {

            when { expression { params.ACTION == 'BUILD' } }

            steps {

                dir('template') {

                    git branch: "${TEMPLATE_BRANCH}",
                        url: "https://${TEMPLATE_REPO}"

                }

            }

        }

    /* ================== SECURITY + STAGING ========================== */

        stage('Build Staging Image') {

            when { expression { params.ACTION == 'BUILD' } }

            steps {

                sh '''
                chmod +x template/scripts/build-image.sh
                template/scripts/build-image.sh staging
                '''

            }

        }

        stage('Deploy Staging Container') {

            when { expression { params.ACTION == 'BUILD' } }

            steps {

                sh '''
                docker stop ${CONTAINER_NAME} || true
                docker rm ${CONTAINER_NAME} || true

                docker run -d \
                --name ${CONTAINER_NAME} \
                --network ci-network \
                -p ${STAGING_PORT}:8080 \
                ${IMAGE_NAME}:staging
                '''

            }

        }

        stage('Security & E2E Tests') {

            when { expression { params.ACTION == 'BUILD' } }

            parallel {

                stage('Trivy Security Scan') {

                    /*
                    steps {

                        sh '''
                        docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/ \
                        aquasec/trivy:latest image \
                        --timeout 10m \
                        --scanners vuln \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        ${IMAGE_NAME}:staging
                        '''

                    }
                    */

                    steps {
                        sh 'echo "trivy scan"'
                    }

                }

                stage('E2E Tests') {

                    steps {

                        sh '''
                        chmod +x template/scripts/e2e-test.sh
                        template/scripts/e2e-test.sh
                        '''

                    }

                }

            }

        }

    /* ================== PRODUCTION ======================= */

        stage('Build & Push Production Image') {

            when { expression { params.ACTION == 'BUILD' } }

            steps {

                sh '''
                chmod +x template/scripts/push-image.sh
                template/scripts/push-image.sh ${IMAGE_TAG}
                '''

            }

        }

        stage('Deploy Existing Image') {

            when { expression { params.ACTION == 'DEPLOY' } }

            steps {

                sh '''
                chmod +x scripts/deploy-existing-image.sh
                scripts/deploy-existing-image.sh ${IMAGE_TAG} ${ENVIRONMENT}
                '''

            }

        }

    }

    post {

        always {

            sh 'docker logout || true'

        }

    }

}