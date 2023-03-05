terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "{{PROJECT_PREFIX}}-terraform-state"
    key    = "eks/terraform.tfstate"
    region = "{{AWS_REGION}}"

    dynamodb_table = "{{PROJECT_PREFIX}}-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "{{AWS_REGION}}"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "{{PROJECT_PREFIX}}-terraform-state"
    key = "network/terraform.tfstate"
    region = "{{AWS_REGION}}"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "{{PROJECT_PREFIX}}-eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

// Not sure this is necessary... wasn't for Kubernetes experiment
resource "aws_iam_role_policy_attachment" "amazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_worker_node_role" {
  name = "{{PROJECT_PREFIX}}-eks-worker-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "amazonEC2ContainerRegistryReadOnlyPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "amazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "{{PROJECT_PREFIX}}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  vpc_config {
    subnet_ids = concat(data.terraform_remote_state.network.outputs.public_subnet_ids, data.terraform_remote_state.network.outputs.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access = true
    public_access_cidrs = ["0.0.0.0/0"]
  }

#  kubernetes_network_config {
#    service_ipv4_cidr = "10.1.64.0/24"
#  }
#
  depends_on = [
    aws_iam_role_policy_attachment.amazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.amazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "eks_worker_node_group" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_role_arn = aws_iam_role.eks_worker_node_role.arn
#  subnet_ids = concat(data.terraform_remote_state.network.outputs.public_subnet_ids, data.terraform_remote_state.network.outputs.private_subnet_ids)
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  // Make these configurable
  instance_types = ["t3.micro"]
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
  timeouts {
    create = "10m"
  }


  depends_on = [
    aws_iam_role_policy_attachment.amazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.amazonEC2ContainerRegistryReadOnlyPolicy,
    aws_iam_role_policy_attachment.amazonEKS_CNI_Policy
  ]
}

output "kubernetes_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "worker_nodes" {
  value = aws_eks_node_group.eks_worker_node_group.resources
}