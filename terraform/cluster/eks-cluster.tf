module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.0.3"
  cluster_name    = var.env_name
  cluster_version = "1.18"
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = var.env_name
  }

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.snyk_security_group_one.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.medium"
      additional_security_group_ids = [aws_security_group.snyk_security_group_two.id]
      asg_desired_capacity          = 1
    },
  ]

  map_roles = [
    {
      rolearn  = data.aws_caller_identity.current.arn
      username = "creator"
      groups   = ["system:masters"]
    },
  ]

  write_kubeconfig = false
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = element(concat(data.aws_eks_cluster.cluster[*].endpoint, tolist([""])), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, tolist([""])), 0))
  token                  = element(concat(data.aws_eks_cluster_auth.cluster[*].token, tolist([""])), 0)
}
