## Permission for Github Action
resource "aws_iam_user" "github_action" {
  name = "github-action"
}

resource "aws_iam_access_key" "github_action" {
  user = aws_iam_user.github_action.name
}

resource "aws_iam_user_policy" "github_action" {
  name   = "github-action-policy"
  user   = aws_iam_user.github_action.name
  policy = file("github-action-policy.json")
}

data "aws_caller_identity" "current" {}

## IAM Group for Developer (vierwer). <Scope within namespace>
resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_role" "developers" {
  name = "eks-developers-role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Action" : "sts:AssumeRole",
          "Condition" : {
            "StringEquals" : {
              "sts:RoleSessionName" : "$${aws:username}"
            }
          }
        }
      ]
    }
  )

  inline_policy {
    name = "describe_eks"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "eks:DescribeCluster"
            ],
            "Resource" : "*"
          }
        ]
      }
    )
  }
}

resource "aws_iam_policy" "developers" {
  name = "eks-developers-policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowAssumeEKSDeveloperRole",
          "Effect" : "Allow",
          "Action" : [
            "sts:AssumeRole"
          ],
          "Resource" : [aws_iam_role.developers.arn]
        }
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "developers" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developers.arn
}

## IAM Group for Team Lead (edit). <Scope within namespace>
resource "aws_iam_group" "leaders" {
  name = "leaders"
}

resource "aws_iam_role" "leaders" {
  name = "eks-leader-role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Action" : "sts:AssumeRole",
          "Condition" : {
            "StringEquals" : {
              "sts:RoleSessionName" : "$${aws:username}"
            }
          }
        }
      ]
    }
  )

  inline_policy {
    name = "describe_eks"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "eks:DescribeCluster"
            ],
            "Resource" : "*"
          }
        ]
      }
    )
  }  
}

resource "aws_iam_policy" "leaders" {
  name = "eks-leaders-policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowAssumeEKSLeaderRole",
          "Effect" : "Allow",
          "Action" : [
            "sts:AssumeRole"
          ],
          "Resource" : [aws_iam_role.leaders.arn]
        }
      ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "leaders" {
  group      = aws_iam_group.leaders.name
  policy_arn = aws_iam_policy.leaders.arn
}



/* Terraform Outputs */
output "github_action_iam_user_arn" {
  value = aws_iam_user.github_action.arn
}

output "github_action_access_key" {
  value = aws_iam_access_key.github_action.id
}

output "github_action_secret_key" {
  value     = aws_iam_access_key.github_action.secret
  sensitive = true
}

output "eks_developer_role" {
  value = aws_iam_role.developers.arn
}

output "eks_leaders_role" {
  value = aws_iam_role.leaders.arn
}
