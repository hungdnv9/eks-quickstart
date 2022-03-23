## Amazon EKS cluster IAM role
## https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html

resource "aws_iam_role" "eks_cluster_general" {
  name = "eks_cluster_general"

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

resource "aws_iam_role_policy_attachment" "general-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_general.name
}

resource "aws_iam_role_policy_attachment" "general-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_general.name
}

resource "aws_iam_role_policy_attachment" "general-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_general.name
}

## Create & Configure EKS cluster
resource "aws_eks_cluster" "eks_cluster_1" {
  name     = "eks_cluster_1"
  version  = "1.21"
  role_arn = aws_iam_role.eks_cluster_general.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.vpc_01_public_snet_ap_north_1a.id,
      aws_subnet.vpc_01_public_snet_ap_north_1c.id,
      aws_subnet.vpc_01_private_snet_ap_north_1a.id,
      aws_subnet.vpc_01_private_snet_ap_north_1c.id,
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
}

## Amazon EKS pod execution IAM role
## https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html
resource "aws_iam_role" "eks_fargate_general" {
  name = "eks_fargate_general"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks-fargate-pods.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "general-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_general.name
}

## Create & Configure Fargate profile
resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = "eks_cluster_1"
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks_fargate_general.arn

  subnet_ids = [
    aws_subnet.vpc_01_private_snet_ap_north_1a.id,
    aws_subnet.vpc_01_private_snet_ap_north_1c.id
  ]

  selector {
    namespace = "kube-system"
  }

  tags = {
    Name = "kube-system"
  }

  depends_on = [aws_eks_cluster.eks_cluster_1]
}

resource "aws_eks_fargate_profile" "quickstart" {
  cluster_name           = "eks_cluster_1"
  fargate_profile_name   = "quickstart"
  pod_execution_role_arn = aws_iam_role.eks_fargate_general.arn

  subnet_ids = [
    aws_subnet.vpc_01_private_snet_ap_north_1a.id,
    aws_subnet.vpc_01_private_snet_ap_north_1c.id
  ]

  selector {
    namespace = "quickstart"
  }

  tags = {
    Name = "quickstart"
  }

  depends_on = [aws_eks_cluster.eks_cluster_1]
}

/* Terraform Outputs */

output "eks_lb_controller_role_arn" {
  value = aws_iam_role.eks_lb_controller.arn
}

output "eks_quickstart_api_app_role_arn" {
  value = aws_iam_role.eks_quickstart_api_app_role.arn
}
