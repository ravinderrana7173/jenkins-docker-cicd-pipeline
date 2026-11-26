# Jenkins + Docker + GitHub CI/CD Pipeline

A hands-on DevOps portfolio project demonstrating an automated CI/CD
workflow using **GitHub, Jenkins, Docker, Nginx, and SonarQube Cloud**.
The pipeline checks out source code, analyzes code quality, enforces a
Quality Gate, builds and tests a Docker image, deploys the application,
performs a health check, and rolls back to the previous container if
deployment or health verification fails.

**Repository:**
https://github.com/ravinderrana7173/jenkins-docker-cicd-pipeline

------------------------------------------------------------------------

## Project overview

This project automates the delivery of a small static website served by
Nginx in a Docker container.

### Pipeline workflow

``` text
Developer
   |
   | git push
   v
GitHub Repository
   |
   | GitHub webhook
   v
Jenkins Pipeline
   |
   +--> Checkout source code
   |
   +--> SonarQube Cloud analysis
   |
   +--> Quality Gate (stop pipeline if it fails)
   |
   +--> Build Docker image
   |
   +--> Automated container test
   |
   +--> Deploy application
   |
   +--> Production health check
   |
   +--> Keep new version or roll back to previous container
```

## Technologies used

  -----------------------------------------------------------------------
  Technology                          Purpose
  ----------------------------------- -----------------------------------
  Git                                 Source-code version control

  GitHub                              Repository hosting and push webhook

  Jenkins                             CI/CD automation

  Docker                              Build and run the application
                                      container

  Nginx                               Serve the static website

  SonarQube Cloud                     Static code analysis and Quality
                                      Gate

  Cloudflare Tunnel                   Temporary public connectivity to
                                      local Jenkins for webhook testing

  PowerShell / WSL2                   Local development environment
  -----------------------------------------------------------------------

## Key features

-   **GitHub-triggered builds:** A push to the configured branch
    triggers Jenkins through a GitHub webhook.
-   **Code quality analysis:** SonarScanner sends the source code to
    SonarQube Cloud.
-   **Quality Gate enforcement:** Jenkins waits for the SonarQube
    result. A failed Quality Gate aborts the pipeline before Docker
    build and deployment.
-   **Docker image build:** Jenkins builds a versioned image using the
    Jenkins build number.
-   **Automated test:** A temporary container is started and the
    application response is checked for the expected page content.
-   **Application deployment:** Jenkins replaces the currently running
    application container with the newly built version.
-   **Production health check:** Jenkins retries the application check
    after deployment.
-   **Rollback:** If starting the new container or its health check
    fails, Jenkins attempts to restore the previous container.
-   **Post-build status:** Jenkins reports pipeline success or failure.

## Repository structure

``` text
jenkins-docker-cicd-pipeline/
├── app/
│   └── index.html
├── Dockerfile
├── Dockerfile.jenkins
├── Jenkinsfile
├── sonar-project.properties
└── .gitignore
```

### Important files

-   `app/index.html` --- Static application page served by Nginx.
-   `Dockerfile` --- Builds the application image from `nginx:alpine`
    and copies the HTML page into the Nginx web root.
-   `Dockerfile.jenkins` --- Builds a custom Jenkins image that includes
    the Docker CLI.
-   `Jenkinsfile` --- Defines the CI/CD stages, testing, deployment,
    health check, and rollback logic.
-   `sonar-project.properties` --- Defines the SonarQube Cloud project
    key, organization, source directory, and encoding.

## Run the application locally

### Prerequisites

-   Windows with Docker Desktop installed and running
-   Git
-   PowerShell

### 1. Clone the repository

``` powershell
git clone https://github.com/ravinderrana7173/jenkins-docker-cicd-pipeline.git
cd jenkins-docker-cicd-pipeline
```

### 2. Build the Docker image

``` powershell
docker build -t ravinder-devops-app:v1 .
```

### 3. Run the container

``` powershell
docker run -d --name devops-portfolio-app -p 8080:80 ravinder-devops-app:v1
```

### 4. Open the application

Visit:

http://localhost:8080

### 5. Check the running container

``` powershell
docker ps
```

### 6. Stop and remove the application container

``` powershell
docker rm -f devops-portfolio-app
```

## Jenkins pipeline setup

The project was tested with Jenkins running in Docker Desktop.

The Jenkins container needs: - Persistent Jenkins data storage. - Docker
CLI installed in the Jenkins image. - Access to a Docker daemon that can
build and run the application image. - The required Jenkins plugins and
credentials.

### Jenkins plugins

The pipeline uses these plugins or integrations:

-   Git
-   GitHub
-   Pipeline
-   Pipeline: Stage View
-   Docker Pipeline
-   Credentials Binding
-   SonarQube Scanner

### Jenkins configuration

Configure the following in Jenkins:

1.  Create a Pipeline job.
2.  Select **Pipeline script from SCM**.
3.  Choose Git and enter the repository URL:
    `https://github.com/ravinderrana7173/jenkins-docker-cicd-pipeline.git`
4.  Set the configured branch (for example, `*/main`).
5.  Set the script path to `Jenkinsfile`.
6.  Configure the GitHub webhook trigger if using webhook-based builds.
7.  Configure the SonarQube Cloud server in **Manage Jenkins → System**.
8.  Configure the SonarScanner installation in **Manage Jenkins →
    Tools**.
9.  Store the SonarQube token in Jenkins Credentials and reference it
    through the SonarQube server configuration. Never commit tokens to
    GitHub.

The `Jenkinsfile` expects the SonarQube server configuration name
`SonarQubeCloud` and scanner installation name `SonarScanner`.

### SonarQube Cloud configuration

The repository includes `sonar-project.properties`. Configure the
matching project and organization in SonarQube Cloud, then connect
Jenkins using a token stored securely in Jenkins Credentials.

The pipeline uses the SonarQube webhook endpoint:

``` text
https://<your-public-jenkins-host>/sonarqube-webhook/
```

The trailing slash is required. If Jenkins runs locally, a temporary
tunnel can provide webhook connectivity for a learning setup. A
temporary Cloudflare Quick Tunnel URL changes and is not a permanent
production endpoint.

## Pipeline stages

  -----------------------------------------------------------------------
  Stage                               What it does
  ----------------------------------- -----------------------------------
  Checkout                            Checks out the repository using
                                      Jenkins SCM configuration

  SonarQube Cloud Analysis            Runs SonarScanner against the
                                      configured source directory

  Quality Gate                        Waits for the SonarQube result and
                                      aborts if the gate fails

  Build Docker Image                  Builds an image tagged with the
                                      Jenkins build number

  Automated Testing                   Starts a temporary container and
                                      checks the served page content

  Deploy Application                  Starts the new application
                                      container and preserves the
                                      previous container temporarily

  Production Health Check             Checks the deployed application and
                                      restores the previous container if
                                      the check fails
  -----------------------------------------------------------------------

## Security and operational notes

This is a **portfolio and learning project**, not a production-hardened
deployment platform.

-   Never commit GitHub Personal Access Tokens, SonarQube tokens,
    passwords, or other secrets.
-   Use Jenkins Credentials for sensitive values.
-   Access to the Docker daemon or Docker socket can provide powerful
    control over the Docker host. The local Docker socket setup used for
    this project should only be used in a trusted learning environment.
    For production, prefer isolated build agents or a carefully secured
    remote builder.
-   A temporary tunnel exposes a route to your local Jenkins instance
    while it is running. Protect Jenkins with authentication and use a
    managed, secured endpoint for production.
-   The current single-container deployment stops the old container
    before starting the new one, so brief downtime is possible. This is
    not a zero-downtime deployment.
-   The rollback logic is a basic demonstration. Production deployments
    should also account for persistent data, readiness checks, traffic
    switching, image retention, and recovery after host or daemon
    failures.
-   The current automated test is a basic HTTP content check, not a
    comprehensive application test suite.

## What I learned

-   Building and troubleshooting a Jenkins pipeline.
-   Connecting GitHub webhooks to a locally hosted Jenkins instance.
-   Building and running Docker images from Jenkins.
-   Integrating SonarQube Cloud analysis into CI/CD.
-   Enforcing a Quality Gate before image build and deployment.
-   Writing basic automated container tests and deployment health
    checks.
-   Implementing and validating a rollback path.
-   Managing Jenkins tools, plugins, credentials, and persistent data.

## Future improvements

Possible next steps include: - Add unit and integration tests. - Publish
versioned images to a container registry. - Add vulnerability scanning
for container images. - Use a staging environment before production
deployment. - Implement blue-green or rolling deployment for reduced
downtime. - Add monitoring and alerting.

------------------------------------------------------------------------

## Author

**Ravinder Singh**

GitHub: https://github.com/ravinderrana7173

------------------------------------------------------------------------

If you find this project useful, feel free to explore the repository and
the pipeline implementation.
