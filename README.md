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
