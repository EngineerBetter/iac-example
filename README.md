# Continuous Infrastructure-as-Code Examples

This repository demonstrates the practices of Continuous Infrastructure as Code
(IaC) from [the companion white
paper](https://github.com/EngineerBetter/iac-paper).

* **Each practice is implemented in a commit** in the history of this
  repository, so that you can see how the practices build on each other. We have
  tagged each commit for easy reference.
* Each practice also a **section in this document** to explain _why_ changes
  were made in a particular way.

Throughout the series of commits, we will build up a solid foundation for many
Continuous IaC practices using [Make](https://www.gnu.org/software/make/),
GitHub, Snyk and Jenkins, amongst other tools.

## How to use this repository

You may wish to read the documentation and examples, and you may also wish to
follow along and run them yourself.

### Reading

If you wish to **understand each practice** in isolation, you should **read
through the commits in order**. This is the **recommended** approach. Each
commit will implement one practice, and add documentation for it. No commits
will change documentation for prior practices.

If you wish to see **only the finished pipeline**, then you should look at the
latest commit.

### Following along

We recommend that you [fork this
repository](https://docs.github.com/en/github/getting-started-with-github/quickstart/fork-a-repo)
so that you may make your own changes, and so that the Jenkins CI server that is
introduced later can push commits to branches for the purpose of promoting
changes between environments.

Once you have forked the repository, make a local clone of it.

You can list all tags and navigate to a
particular tag by running `git log --oneline` and `git checkout {tag_name}` (for
example, `git checkout 01-starting`) respectively.

You can return to the latest commit with `git checkout main`.

To get your Jenkins CI server to use your fork (rather than the original!) you
will need to set an environment variable before setting your pipelines. This is
because we can't know in advance what the Git URL of your fork will be. We'll
assume that your fork is stored on GitHub.

#### Dependencies

To follow along you may need some or all of the tools used throughout the
examples in this repository. Here's a list of everything used:

- `aws-cli` (`>=2.2.7`) - Use
  [the official installation instructions](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- `aws-iam-authenticator` (`>=1.19.6`) - Use
  [the official installation instructions](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
- `terraform` (`1.15.4`) - we've used
  [`tfenv`](https://github.com/tfutils/tfenv#installation) to install specific
  versions of Terraform
- `kubectl` (`>=1.21.1`) - Use
  [the official installation instructions](https://kubernetes.io/docs/tasks/tools/)
- `snyk` (`>=1.616.0`) - Use
  [the official installation instructions](https://support.snyk.io/hc/en-us/articles/360003812538-Install-the-Snyk-CLI)
- `tflint` (`>=0.28.1`) - Use
  [the official installation instructions](https://github.com/terraform-linters/tflint#installation)
- `docker` (latest version) - Use
  [the official installation instructions](https://docs.docker.com/get-docker/)
- `jre` (Java Runtime Environment, version 8) - Use
  [the official installation instructions](https://www.oracle.com/uk/java/technologies/javase-jre8-downloads.html)
- `golang` (`>=1.16.4`) - Use
  [the official installation instructions](https://golang.org/doc/install)
- `chromedriver` (`>=90.0.4430.24`) - Use
  [the official installation instructions](https://chromedriver.chromium.org/downloads),
  make sure to install version `90.*` and not `91.*`.
- `conftest` (`>=0.25.0`) - Use
  [the official installation instructions](https://www.conftest.dev/install/)

You may wish to install all of these tools now. Alternatively, you may install
the tools as you encounter them (you'll need the `aws-iam-authenticator` for any
`kubectl` commands).

#### Jenkins CLI

The Jenkins CLI is required from step 7 onwards. It is installed by downloading
the jar from your own Jenkins instance (instructions on setting up Jenkins
follow if you don't have Jenkins CI yet).

The jar is downloaded with:

```terminal
curl -o jenkins-cli.jar {your_jenkins_host}/jnlpJars/jenkins-cli.jar
```

Store this jar wherever is convenient for you on your machine, we'll be using it
later.

#### Dependencies for a local Jenkins CI

If you don't already have a Jenkins CI installed the instructions for doing so
are described in [JENKINS.md](/JENKINS.md) (although you won't need Jenkins
until section 7). In addition to the steps in that section, you'll need the
following tools installed:

- `helm` (`>=3.0.0`) - Use
  [the official installation instructions](https://helm.sh/docs/intro/install/)
- `helmfile` (`>=0.139.7`) - Use
  [the official installation instructions](https://github.com/roboll/helmfile#installation)
- `helm-diff` - Use
  [the official installation instructions](https://github.com/databus23/helm-diff#install)

#### Allowing Jenkins to authenticate with GitHub

Later Jenkins will need to be able to both clone your fork of this repository,
and also push changes back to branches in your fork. To do this it will need to
be able to authenticate with GitHub via a [deploy
key](https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys).

Create a new keypair in the `$HOME/.ssh/` directory:

```terminal
ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/local-jenkins -q -N ""
```

Next, tell GitHub about the public half of the keypair:

* Copy the entire contents of `$HOME/.ssh/local-jenkins.pub` to your paste
  buffer
* Visit your repository in GitHub
* Visit the "Settings" page of your repository
* Select "Deploy Keys" in the left-hand menu
* Entire a title of "Local Jenkins" or any other name that will allow you to
  remember what this key is
* Paste the contents of the public key file into the large text box
* Ensure you tick the "Allow write access" box, otherwise Jenkins will not be
  able to push changes later

Finally, tell Jenkins about the private half of the keypair:

* Copy the entire contents of `$HOME/.ssh/local-jenkins` to your paste buffer
* Log in to your Jenkins instance ([http://localhost](http://localhost)
  `admin`/`p4ssw0rd` if you use [JENKINS.md](/JENKINS.md))
* Visit the "Manage Jenkins" page
* Select "Manage Credentials"
* Select the "Jenkins Credential Provider"
* Select "Global credentials"
* Select "Add credentials"
* Provide a "Username" and "ID" of `git`
* Paste the contents of the private key file into the large text box (you may
  need to click buttons for it to appear)
* Click "Save"

#### Snyk account and API token

We'll be using Snyk's CLI tool to find misconfigurations. In addition to
installing the CLI (instructions above), you'll need a Snyk account and a Snyk
token.
[Create a Snyk account](https://support.snyk.io/hc/en-us/articles/360017098237-Create-a-Snyk-account)
and a
[Snyk API token](https://support.snyk.io/hc/en-us/articles/360004008258-Authenticate-the-CLI-with-your-account)
and make a note of your token, we'll need it later.

## Practices

Not all practices are represented in this repository, as some are non-technical.

The below links will take you to the appropriate point in Git history for each
practice.

1. [The starting point](https://github.com/EngineerBetter/iac-example/tree/01-starting#the-starting-point)
1. [Store `.tfstate` appropriately](https://github.com/EngineerBetter/iac-example/tree/02-store-tf-state#store-tfstate-appropriately)
1. [Statically test IaC files](https://github.com/EngineerBetter/iac-example/tree/03-static-test#statically-test-iac-files)
1. [Write files in a standardized way](https://github.com/EngineerBetter/iac-example/tree/04-linting-formatting#write-files-in-a-standardized-way)
1. [Automatically format, lint and test before committing changes](https://github.com/EngineerBetter/iac-example/tree/05-pre-commit-hook#automatically-format-lint-and-test-before-committing-changes)
1. [Dynamically test against environments](https://github.com/EngineerBetter/iac-example/tree/06-dynamic-test#dynamically-test-against-environments)
1. [Automatically test and apply IaC](https://github.com/EngineerBetter/iac-example/tree/07-automatically-apply#automatically-test-and-apply-iac)
1. [Make all jobs idempotent](https://github.com/EngineerBetter/iac-example/tree/08-idempotent#make-all-jobs-idempotent)
1. [Continually apply IaC](https://github.com/EngineerBetter/iac-example/tree/09-converge#continually-apply-iac)
1. [Alert on failures](https://github.com/EngineerBetter/iac-example/tree/10-alert#alert-on-failures)
1. [Smoke-test deployed applications](https://github.com/EngineerBetter/iac-example/tree/11-smoke-test#smoke-test-deployed-applications)
1. [Test that everything works together](https://github.com/EngineerBetter/iac-example/tree/12-integration-test#test-that-everything-works-together)
1. [Record which versions work together](https://github.com/EngineerBetter/iac-example/tree/13-record-versions#record-which-versions-work-together)
1. [Parameterize differences between environments](https://github.com/EngineerBetter/iac-example/tree/14-parameterise-environments#parameterize-differences-between-environments)
1. [Promote change](https://github.com/EngineerBetter/iac-example/tree/15-promote#promote-change)

### The starting point

Many of the practice implementations are series of commands, chained together in
shell scripts. In order to make these easy to use for engineers as well as easy
to invoke from Jenkins, we've used a [Makefile](/Makefile). This is a file that
is interpreted by the [GNU Make tool](https://www.gnu.org/software/make/).

We chose to use Make because it is common and convenient, but you don't have
to. You could save scripts in individual files, or even embed them in the
pipeline definition. Make will be available by default on many systems.

This repository has assumed the existence of some simple deployments that we'll
build automation around. The first commit in this repository includes Terraform
files for deploying a Kubernetes cluster to AWS, and a Kubernetes manifest to
deploy the [Sock Shop](https://microservices-demo.github.io/) microservices
application to that cluster.

#### Following along

```terminal
# Set up environmental variables to authenticate to AWS.
# You may instead store these in a `.envrc` file if using `direnv`.
export AWS_ACCESS_KEY_ID={your_aws_access_key_id}
export AWS_SECRET_ACCESS_KEY={your_aws_secret_access_key}

# Deploy the Kubernetes cluster using Terraform. The first this this runs,
# expect it to take between 15 - 25 minutes.
make deploy-cluster

# Get the Kubernetes config file you'll use to communicate with the Kubernetes
# cluster.
make fetch-cluster-config

# Deploy the sock-shop microservice application to Kubernetes
make deploy-sock-shop

# Sock Shop may take a few minutes to deploy, but you can check its progress
# with this command. You're finished with this section once Sock Shop reports
# it is "Ready".
kubectl --kubeconfig secrets/config-prod.yml get all -n sock-shop
```

### Store `.tfstate` appropriately

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/01-starting...02-store-tf-state)

In the previous step, Terraform's state (where Terraform remembers what is
deployed at the moment) was stored locally on disk in a `.tfstate` file that was
ignored by Git. This change introduces a remote store for that state such that
it is no longer kept on your workstation.

A bootstrap Make target as been added (`make terraform-bootstrap`) that will
create the following AWS resources to manage state remotely:

1. A S3 bucket to store the `.tfstate` file
1. A DynamoDB table that is used as a lock such that simultaneous changes to the
   infrastructure are prevented

#### Following along

```terminal
# Set up the following environmental variables for the remote state. You may store
these in a `.envrc` file if using `direnv`.

# The region where state resources are to be created, we used `eu-west-2`
export BOOTSTRAP_AWS_REGION={your_aws_region}

# The name of the S3 bucket to store state, such as `terraform_state`
export BOOTSTRAP_BUCKET_NAME={your_aws_bucket_name}

# The DynamoDB table name used for locking, such as `terraform_lock`
export BOOTSTRAP_DYNAMO_TABLE_NAME={your_dynamodb_table}

# Create the bucket and locking table, the AWS CLI may display output to the
# screen that you can dismiss by pressing `q`. Note that this script will fail
# if run multiple times, we'll address this later.
make terraform-bootstrap

# Initializing again will configure your remote Terraform backend. You should
# be prompted to decide if you'd like to migrate your local state to the S3
# bucket, which you absolutely do.
make terraform-init

# Remove the now unnecessary local state files.
rm terraform/deployments/cluster-prod/*.tfstate
rm terraform/deployments/cluster-prod/*.tfstate.backup

# Running deploy again should validate that nothing is going to change even
# though we've changed where state is stored.
make deploy-cluster

# You're now finished with this section.
```

### Statically test IaC files

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/02-store-tf-state...03-static-test)

In order to improve confidence in the correctness and safety of the resources
deployed by Terraform and Kubernetes, static testing is introduced. Make sure
your have your Snyk API token to hand that
[you created earlier](https://github.com/EngineerBetter/iac-example#snyk-account-and-api-token).

#### Following along

```terminal
# Used by the Snyk CLI for authentication when performing scans
export SNYK_TOKEN={your_snyk_token}

# Using the Terraform CLI, this task checks our Terraform files for correctness
# and whether or not we're using deprecated Terraform features.
make terraform-validate

# This target uses Snyk to determine whether misconfigurations in the Terraform
# definitions would result in issues (such as security issues leading to
# exposure to risk).
make snyk-test-terraform

# This target uses the Snyk tool to perform a similar check against the
# deployment manifest we used to deploy Sock Shop to Kubernetes. This target
# will likely fail as there are issues with the Sock Shop manifest. We'll
# ignore failure here for the time being but note that there are configuration
# issues with this manifest identified by Snyk.
make snyk-test-deployments

# This is a convenience target that'll run the above three targets sequentially.
make test
```

It is advisable to run `make test` prior to applying any changes to your
infrastructure or application to increase your confidence. Later, it will be
demonstrated how this may be automated.

### Write files in a standardized way

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/03-static-test...04-linting-formatting)

Keeping code standardized will improve readability of the files. We can enforce
standardization using tools that are triggered by Make for convenience.

#### Following along

```terminal
# This target uses Terraform's `fmt` subcommand to indicate when files are
# formatted in a non-standard way. If it finds a formatting issue then it'll
# fail and tell you what you need to do to fix it.
make terraform-fmt-check

# There are no formatting errors in the files, so the tool exits without error.
# You can prove this by printing the exit code of the last command, which will be
# 0.
echo $?

# This target uses tflint to to provide faster feedback for errors that are
# _syntactically_ correct but _semantically_ incorrect (such as asking AWS to
# create an instance type that does not exist).
make terraform-lint
```

Try making edits to the files before running the checks again, to see if you can
get them to output a warning.

Seeing these commands pass successfully concludes this section. For convenience,
both of these two tests are run within the existing target `make test`.

### Automatically format, lint and test before committing changes

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/04-linting-formatting...05-pre-commit-hook)

Until now, the person making changes had to remember to to run tests and checks
prior to applying changes to either Terraform or Kubernetes. In this change, [a
pre-commit hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) is
configured such that fast tests are run automatically when checking in new
changes to Git.

#### Following along

```terminal
# Configure the pre-commit hook. After running this, each time a commit is made
# Git will run the targets `terraform-validate`, `terraform-lint` and
# `terraform-fmt-check`. Only these tests are run because they are fast.
make configure-pre-commit-hook

# Try making a simple commit to see the hook trigger.
touch a-new-file
git add a-new-file
git commit -m "testing the pre-commit hook"

# You'll see the tests running automatically.
```

Having configured your pre-commit hook, you've finished this section.

#### Removing the Git hook

You may wish to remove the git hook in future or disable it temporarily. To
remove the hook run `rm .git/hooks/pre-commit`. It can be re-enabled by running
`make configure-pre-commit-hook` again.

### Dynamically test against environments

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/05-pre-commit-hook...06-dynamic-test)

To further increase confidence in the infrastructure being deployed, this change
makes use of Snyk's Terraform plan-scanning feature.

Rather than immediately applying changes to infrastructure, a plan is now
generated first and scanned by Snyk before applying those changes. If Snyk finds
issues with the generated plan then the deployment is aborted.

#### Following along

```terminal
# Running this target now makes use of Snyk's IaC plan scanning. This will
# likely fail when run and output useful information about properly configuring
# the Terraform files.
make deploy-cluster

# Since we still need to deploy to production despite issues that may already
# exist there, we've added a toggle to not consider finding configuration issues
# an error, but merely report on issues found.
IGNORE_SNYK_TEST_PLAN_FAILURE=true make deploy-cluster
```

This concludes this section, where deploys with the feature toggle should report
no deployment changes, but warn about configuration issues.

### Automatically test and apply IaC

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/06-dynamic-test...07-automatically-apply)

Prior to this change, deployments and tests have been run locally on development
machines. This presents a few issues, the most important of which being that an
engineer making deploys could forget to run tests prior to deploying and that
it's difficult for other contributors to see what was deployed recently.

To address these issues, Jenkins CI pipelines have been introduced. The Make
targets that have been used for deploys and tests are run automatically whenever
Jenkins detects a code change.

Each time a commit is pushed to this repository, the `Deploy` pipeline is
triggered. This pipeline does the following each time it is run, in this order:

1. Run `make terraform-init`
2. In parallel, run:
   - `make terraform-validate`
   - `make terraform-lint`
   - `make terraform-fmt-check`
   - `make snyk-test-terraform`
   - `make snyk-test-deployments`
3. Run `make deploy-cluster`
4. Run `make deploy-sock-shop`

At each push to this repository, all tests are run, the Kubernetes cluster is
deployed and the Sock Shop application is deployed. By using this, we need not
fear that we forget to run tests prior to making changes to the infrastructure.
We also now have a view of the history of changes through Jenkins CI build
history.

A `Destroy` pipeline has also been created. This pipeline is disabled
by default to prevent accidental running, as its role is to destroy the
application and Kubernetes cluster. While you're unlikely to want to do this
for your production deployments, this functionality will become useful in later
commits when we look at using multiple environments.

#### Following along

You may already have access to a running Jenkins instance. If you don't, please
follow the instructions in [JENKINS.md](/JENKINS.md) to deploy Jenkins locally.

In order to run our Make targets in Jenkins, we'll need to let Jenkins know
about a few credentials. Refer to the
[Jenkins documentation for configuring credentials](https://www.jenkins.io/doc/book/using/using-credentials/).
Below are a list of credentials we'll need, including their key and type. Their
values are the same as those you've already configured in earlier steps.

| Key                         | Type        |
|-----------------------------|-------------|
| SNYK_TOKEN                  | Secret text |
| AWS_ACCESS_KEY_ID           | Secret text |
| AWS_SECRET_ACCESS_KEY       | Secret text |
| BOOTSTRAP_AWS_REGION        | Secret text |
| BOOTSTRAP_BUCKET_NAME       | Secret text |
| BOOTSTRAP_DYNAMO_TABLE_NAME | Secret text |

```terminal
# In order to create pipelines in our Jenkins instance, we'll need to set a few
# environment variables.
# You may instead store these in a `.envrc` file if using `direnv`.

# If you've forked this repo, these variables are used to instruct Jenkins on
# where it can find your fork.
# If different from "EngineerBetter":
export GITHUB_ORG={your_github_org}
# If different from "iac-example":
export GITHUB_REPOSITORY={your_github_repository}

# The Make targets we're about to use need to use the Jenkins CLI so we set this
# to enable the target to find it.
export JENKINS_CLI={your_cli_path}

# The following variables are used to communicate and authenticate with Jenkins.

# The URL to your Jenkins instance, if you used JENKINS.md then its value should
# be `http://localhost/`.
export JENKINS_URL={your_jenkins_url}

# The following are the Jenkins credentials, if you used JENKINS.md then their
# values are `admin` and `p4ssw0rd` respectively.
export JENKINS_USERNAME={your_jenkins_username}
export JENKINS_PASSWORD={your_jenkins_password}

# The following will create two declarative pipelines (see
# https://www.jenkins.io/doc/book/pipeline/syntax/) in Jenkins - one for
# deploying the infrastructure and one for destroying it. After running these
# commands, this section is concluded.
make jenkins-create-deploy-pipeline
make jenkins-create-destroy-pipeline
```

Explore the Jenkins web user interface to see your newly-created pipelines. You
can trigger a build to see them in action.

#### Notes: Updating the pipelines

The first time we created the Jenkins pipelines, we used the commands just
above. If you need to modify and set the pipelines again, you should use the
Make targets `jenkins-update-deploy-pipeline` and
`jenkins-update-destroy-pipeline`. This is because Jenkins' CLI has no way to
"create a pipeline _or_ update it if it already exists" - they are separate
operations.

Pipeline metadata lives in [deploy.Jenkinsfile](/pipelines/deploy.Jenkinsfile)
and [destroy.Jenkinsfile](/pipelines/destroy.Jenkinsfile). Since it can be
difficult to read and change XML files, it's recommended you make any changes
you need to make to pipeline metadata in the Jenkins UI and use the Jenkins CLI
to get the pipeline definition, updating the XML files with the newly generated
ones:

```terminal
java -jar \
  $JENKINS_CLI \
  -s $JENKINS_URL \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  get-job 'Deploy (prod)' \
  > pipelines/deploy.xml
```

#### Notes: Docker images

Our pipelines use Kubernetes agents to run their workloads. We've provided a
Docker image that the pipelines already know about (engineerbetter/iac-example).

If you wish to create your own Docker images for use by modifying the Dockerfile
in this repository, you can run
`docker build . -t {your_image_repository}/{your_image_name}:{your_image_tag}`
to build the image and
`docker push {your_image_repository}/{your_image_name}:{your_image_tag}` to push
the image.

Refer to the
[Dockerhub getting started guide](https://docs.docker.com/docker-hub/) (or the
documentation for whatever image repository you use).

If you have built your own image and wish to use it, make sure you replace the
image references in both [deploy.Jenkinsfile](/pipelines/deploy.Jenkinsfile) and
[destroy.Jenkinsfile](/pipelines/destroy.Jenkinsfile). You can retrieve the
SHA256 of your image with
`docker image inspect {your_image_repository}/{your_image_name}:{your_image_tag}`
and looking for the "RepoDigests".

### Make all jobs idempotent

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/07-automatically-apply...08-idempotent)

When Jenkins CI was introduced in the previous commit, we automated almost
everything. One thing that was missing was the 'bootstrap' Make target which
created the AWS resources required for the Terraform backend. That target only
works the first time it is run: if the resources already exist, it errors.

In this commit we make the bootstrap Make target idempotent so that it may be
safely run in CI along with all other Make targets, automating what was
previously a manual step.

Prior to creating the bootstrap S3 bucket and DynamoDB table, the script now
checks if they already exist, so that it does not fail if they are already
there. With this change it is now safe to run that target repeatedly and be sure
that the end state will be the same.

Given this new safety, this step is introduced into the CI pipeline in Jenkins,
removing a dependency on what was previously a manual step.

#### Following along

Our Jenkins pipeline is currently configured to build from a specific tag (the
tag of the last step). We need to tell Jenkins that it should now be looking at
_this_ tag.

Unfortunately Jenkins has a bug which means that it might not 'notice' that the
tag it is being told to watch has changed. Triggering a build does force it to
recognise that it is configured to watch a new tag.

You will need to update your pipeline definitions, and also trigger a build to
force it to update.

```terminal
# Update the pipelines
make jenkins-update-deploy-pipeline
make jenkins-update-destroy-pipeline

# Trigger a build
java -jar ${JENKINS_CLI} \
  -s ${JENKINS_URL} \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  build 'Deploy (prod)'
```

### Continually apply IaC

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/08-idempotent...09-converge)

The pipeline is now triggered at least once per hour, even if nothing changes.
This is safe to do since our tasks are now idempotent and running the pipeline
repeatedly ought to result in the same outcome.

This change ensures that manual changes are overwritten at least every hour,
encouraging change to move through CI via Git commits.

#### Following along

```terminal
# Update the pipelines, and trigger a build to force Jenkins to notice the
# change in tag.
make jenkins-update-deploy-pipeline
make jenkins-update-destroy-pipeline
java -jar ${JENKINS_CLI} \
  -s ${JENKINS_URL} \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  build 'Deploy (prod)'
```

Visit the [Deploy (prod)](http://localhost/job/Deploy%20(prod)/configure)
configuration page, and see that there are now settings for an hourly build
trigger.

### Alert on failures

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/09-converge...10-alert)

Prior to this change, failures in CI would only be visible by inspecting the
Jenkins build history. This is fine when people are constantly checking Jenkins
but that isn't always a realistic approach. Important information ought to be
_pushed_ to the those who need to know it rather than expecting those people to
be constantly checking for it.

In this commit, our pipelines are configured to alert to a Slack channel with a
link to the failing build, grabbing the attention of those able to fix the issue
and ensuring the pipeline is failing for a smaller window of time.

To enable Jenkins to post to Slack, you'll need to configure a Jenkins
credential `SLACK_WEBHOOK_CREDENTIAL` of type "secret text". Configuring Jenkins
credentials was covered in
[Automatically test and apply IaC](https://github.com/EngineerBetter/iac-example/tree/10-alert#automatically-test-and-apply-iac).
The value for this secret is created by following
[Slack's tutorial on setting up webhooks](https://slack.com/intl/en-gb/help/articles/115005265063-Incoming-webhooks-for-Slack).

#### Following along

You will need to update your pipeline definitions for the alerting configuration to take effect:

```terminal
# Configure the slack channel that failures are reported to.
# You may instead store these in a `.envrc` file if using `direnv`.
export SLACK_CHANNEL={your_alerts_channel}

# Update the pipelines, and trigger a build to force Jenkins to notice the
# change in tag.
make jenkins-update-deploy-pipeline
make jenkins-update-destroy-pipeline
java -jar ${JENKINS_CLI} \
  -s ${JENKINS_URL} \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  build 'Deploy (prod)'
```

### Smoke-test deployed applications

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/10-alert...11-smoke-test)

Smoke tests are often used to get fast feedback on whether deployed systems are
functioning as they expect. While not rigorous tests, they often answer the
question "is something on fire?". In this commit, we introduce smoke tests after
our infrastructure is deployed to increase our confidence that things are
functioning as expected.

We've leveraged functionality in Kubernetes to achieve rudimentary smoke tests -
we've defined a readiness probe on the front end of Sock Shop that expects a
`200 OK` response when fetching the landing page content.

In addition, when deploying Sock Shop, we use `kubectl` to wait for all pods and
resources to report that they are `ready`. Previously this wasn't checked for
and we'd not have known that deploying Sock Shop had failed.

#### Following along

```terminal
# Update the pipelines, and trigger a build to force Jenkins to notice the
# change in tag.
make jenkins-update-deploy-pipeline
make jenkins-update-destroy-pipeline
java -jar ${JENKINS_CLI} \
  -s ${JENKINS_URL} \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  build 'Deploy (prod)'
```

Triggering the "Deploy (prod)" pipeline and observing the "Deploy Sock
Shop" stage should indicate that the pipeline waited until the pods reported
they were ready (that pods were deployed and their readiness probes were
successful).

You can validate that the script waited for readiness probes to return
successfully by looking for a number of lines containing `condition met` in the
build output.

### Test that everything works together

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/11-smoke-test...12-integration-test)

Our earlier smoke tests gave us some good assurances that we will catch issues
with individual services, but only by testing one component of our deployment in
isolation. In this section we introduce an example of slightly more rigorous
testing. Ideally these tests would be maintained by the people who maintain the
Sock Shop application code.

Our new integration tests will load the front end and ensure that a particular
section exists in that page content. Now we've guarded against more complicated
failures such as the front end having no content but returning `200 OK`, or
returning the wrong content.

#### Following along

You can run the integration tests locally, if you have all of the prerequisites
installed:

```terminal
# Ensure that our cluster config is up to date so that we can communicate with
# Kubernetes.
make fetch-cluster-config

# Run the integration tests from our local machine
make integration-test
```

In this tag the integration tests are also run as part of the pipeline. To see
them run automatically:

```terminal
# Update the pipelines, and trigger a build to force Jenkins to notice the
# change in tag.
make jenkins-update-deploy-pipeline
make jenkins-update-destroy-pipeline
java -jar ${JENKINS_CLI} \
  -s ${JENKINS_URL} \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  build 'Deploy (prod)'
```

...and look for the integration test job.

### Record which versions work together

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/12-integration-test...13-record-versions)

There are many ways to maintain a "bill of materials" that declares what is to
be deployed and what is deployed at the moment. It's not quite true that we've
been entirely declarative in our infrastructure and application deployments up
to now. We're going to make sure that this repository contains specific version
definitions for what is deployed right now.

Our Kubernetes deployment manifest for Sock Shop has been referencing which
images it needs by tag, for example `mongo:latest`. The image version that tags
point to can be changed by the owner of the image. Indeed, some tags such as
`latest` are _intended_ to be updated constantly. To be more confident in our
deployment process being reproducible and idempotent, we'd like to make sure
that the versions of images are not changing underneath us between deploys. This
is achieved by referencing each image's SHA256, rather than their tags.

For each image in the deployment manifest, we've updated the reference to the
SHA256 of the image deployed at the moment.

#### Following along

You can run this test locally:

```terminal
# To ensure that we continue to reference images by SHA256, we've added conftest
# to inspect deployment manifests and fail if it finds an image not referenced
# by SHA256.
make policy-test
# Verify that the previous command exited successfully
echo $?
```

You could try switching some of the versions to `latest` to see the test fail.

Observe that the new Make target is also run by the latest version of the
pipeline:

```terminal
# Update the pipelines, and trigger a build to force Jenkins to notice the
# change in tag.
make jenkins-update-deploy-pipeline
make jenkins-update-destroy-pipeline
java -jar ${JENKINS_CLI} \
  -s ${JENKINS_URL} \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  build 'Deploy (prod)'
```

...and look for the "Policy Test" job.

 This section is now concluded.

### Parameterize differences between environments

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/13-record-versions...14-parameterise-environments)

Until this commit, we've been assuming that there is only one environment: prod.
One of the key benefits of IaC is that it becomes easy to create and destroy
infrastructure. To unlock this power we need to make very little change to our
repository.

An environment variable, `TF_VAR_env_name`, has been introduced that will be
used by Terraform to determine which environment it is to deploy.

#### Following along

```terminal
# Configure the environment we're interacting with. Make targets will fail if
# run without an environment configured.
# You may instead store this in a `.envrc` file if using `direnv`.
export TF_VAR_env_name=prod

# Update the pipelines, and trigger a build to force Jenkins to notice the
# change in tag.
make jenkins-update-deploy-pipeline
make jenkins-update-destroy-pipeline
java -jar ${JENKINS_CLI} \
  -s ${JENKINS_URL} \
  -auth "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
  build 'Deploy (prod)'

# Switch environments to "staging". Every operation is now run against a
# different environment.
export TF_VAR_env_name=staging

# Create deploy and destroy pipelines for the staging environment. These new
# pipelines will operate on "staging" and not interfere with "prod".
make jenkins-create-deploy-pipeline
make jenkins-create-destroy-pipeline
```

You can create as many environment as you like, the only limit is your budget!
Simply changing `TF_VAR_env_name`'s value will achieve that. This section is now concluded.

### Promote change

* [See code changes](https://github.com/EngineerBetter/iac-example/compare/14-parameterise-environments...15-promote)

Given how easy it is to create new environments now that they are parameterized,
it is trivial to demonstrate another practice used in IaC: promotion.

We've decided to use Git branches to implement promotion in Jenkins. When a
deploy is successful, the branch called `passed_{env_name}` is rebased to the
Git commit of what was just deployed. In practice we've created a `staging`
environment and pipelines, and when a `staging` deploy is successful, it pushes
the branch `passed_staging`. Our production environment is configured to deploy
on change to the `passed_staging` branch and when successful, the `prod`
pipeline pushes to `passed_prod`.

So that knowledge of environment names exists outside of our heads, we've created
an `environments.yml` file. The Make targets have been modified such that acting on an
environment not referenced in that file will fail with a message explaining why.

Each environment requires the `name` and `promotes_to` fields to be set in the
`environments.yml` file. `promotes_to` is used to determine which branch to push
_to_ when a deploy is successful. An optional `promotes_from` field may be set
that determines which branch triggers the pipeline. It defaults to `main`.

#### Notes

Unfortunately the Jenkins Git plugin does not function correctly in declarative
pipelines. A consequence of this is that we were unable to `git push` from our
deploy pipelines. As a workaround we've configured the deploy pipeline to
trigger a
[freestyle project](https://docs.cloudbees.com/docs/admin-resources/latest/pipelines/learning-about-pipelines#_freestyle_projects)
to perform `git push`.

This made updating Jenkins pipelines a bit unwieldy since there are now at least
three pipelines to set. As a convenience, `make jenkins-update-pipelines` and
`make jenkins-create-pipelines` will set all pipelines for an environment.

#### Following along

```terminal
# Remove the no-longer used environment variable. If using `direnv` then remove
# it from your .envrc instead.
unset TF_VAR_env_name

# Use ENV_NAME to indicate which environment we're operating on. It must match
# an environment referenced in environments.yml.
# You may instead store this in a `.envrc` file if using `direnv`.
export ENV_NAME=prod

# Create the promotion pipeline used to promote change between environments.
make jenkins-create-promote-pipeline

# To move the tutorial on, make sure we instruct Jenkins to look at the source
# code at this tag.
make jenkins-update-pipelines

# Update the staging pipelines too.
export ENV_NAME=staging
make jenkins-update-pipelines
```

This concludes this section. Feel free to push a trivial change and observe
promotion in action. Pushes to `main` will trigger the staging pipeline, which
will trigger the prod pipeline after success.
