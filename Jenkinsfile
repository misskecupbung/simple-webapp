pipeline {
  agent {
    label "kube-agent"
  }
  
  environment {
    // Adjust variables below
    ARGOCD_SERVER = "10.4.6.10:32218"
    APP_MANIFEST_REPO = "https://github.com/btech-training-team/simple-webapp-manifest.git"
    IMAGE_NAME = "docker.io/atwatanmalikm/webapp"

    // Don't change variables below
    TAG = sh (script: "date +%y%m%d%H%M", returnStdout: true).trim()
    ARGOCD_OPTS = "--grpc-web --insecure"
    APP_MANIFEST_PATH = sh (script: "echo $APP_MANIFEST_REPO | sed 's/.*github.com//g'", returnStdout: true).trim()
  }
  
  stages {
    stage('Preparation') {
      steps {
        container('webapp-agent') {
          sh "echo App Version = $TAG"
        }
      }
    }

    stage('Test') {
      steps {
        container('webapp-agent') {
          sh "html5validator html/index.html"
        }
      }
      post {
        success {
           echo "Test Successful"
        }
        failure {
           echo "Test Failed"
        }
      }
    }
    
    stage("Build & Push Image"){
      steps{
        container('kaniko'){
          sh """
          /kaniko/executor --dockerfile `pwd`/Dockerfile --context `pwd` \
          --verbosity debug --destination $IMAGE_NAME:$TAG
          """
        }
      }
      post {
        success {
           echo "Build & Push Successful"
        }
        failure {
           echo "Build & Push Failed"
        }
      }
    }

    stage('Approval') {
      steps {
         input(
           message: "Deploy application with ${TAG} version to production ?",
           ok: 'Yes, deploy it'
         )
      }
    }

    stage('Update Manifest') {
      steps {
        container('webapp-agent') {
          script {
            withCredentials([usernamePassword(credentialsId: 'github-cred',
                 usernameVariable: 'username',
                 passwordVariable: 'password')]){
                  sh("""
                  git clone $APP_MANIFEST_REPO
                  cd simple-webapp-manifest
                  sed -i "s/webapp:.*/webapp:$TAG/g" deployment.yaml
                  git config --global user.email "example@main.com"
                  git config --global user.name "example"
                  git add . && git commit -m 'update image tag'
                  git push https://$username:$password@github.com$APP_MANIFEST_PATH main
                  """)
            }
          }
        }
      }
    }

    stage("Sync App ArgoCD"){
      steps{
        container('argocd'){
          script {
            withCredentials([string(credentialsId: 'argocd-cred', variable: 'ARGOCD_AUTH_TOKEN')]){
                  sh("""
                  export ARGOCD_SERVER='$ARGOCD_SERVER'
                  export ARGOCD_OPTS='$ARGOCD_OPTS'
                  argocd app sync simple-webapp
                  """)
            }
          }
        }
      }
    }
  }
}
