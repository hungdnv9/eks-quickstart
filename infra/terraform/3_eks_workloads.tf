## ADD INDENTIY PROVIDER
## https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
## https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/setting-up-enable-IAM.html
data "tls_certificate" "eks_cluster_1" {
  url = aws_eks_cluster.eks_cluster_1.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster_1" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_1.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster_1.identity[0].oidc[0].issuer
}

## Load Balancer Controller - Service Account
resource "aws_iam_role" "eks_lb_controller" {
  name = "eks_lb_controller"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.eks_cluster_1.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(aws_iam_openid_connect_provider.eks_cluster_1.url, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_lb_controller_policy" {
  name   = "eks_lb_controller_policy"
  role   = aws_iam_role.eks_lb_controller.name
  policy = file("alb-policy.json")
}

## API App - Service Account
resource "aws_iam_role" "eks_quickstart_api_app_role" {
  name = "eks-quickstart-api-app-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.eks_cluster_1.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(aws_iam_openid_connect_provider.eks_cluster_1.url, "https://", "")}:sub" : "system:serviceaccount:quickstart:api-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_quickstart_api_app_policy" {
  name   = "eks_quickstart_api_app_policy"
  role   = aws_iam_role.eks_quickstart_api_app_role.name
  policy = file("api-policy.json")
}

## ECR
resource "aws_ecr_repository" "eks_quickstart" {
  name                 = "eks_quickstart"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


/* Terraform Outputs */

output "ecr_repo_url" {
  value = aws_ecr_repository.eks_quickstart.repository_url
}

