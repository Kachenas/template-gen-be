data "aws_iam_policy_document" "ssm_bastion_access" {
  statement {
    sid     = "StartSessionToBastion"
    actions = ["ssm:StartSession"]
    resources = [
      var.bastion_instance_arn,
      "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSessionToRemoteHost",
      "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell",
    ]
  }

  statement {
    sid       = "ManageOwnSessions"
    actions   = ["ssm:TerminateSession", "ssm:ResumeSession"]
    resources = ["arn:aws:ssm:*:*:session/$${aws:username}-*"]
  }

  statement {
    sid       = "DescribeForCliAndConsole"
    actions   = ["ssm:DescribeSessions", "ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm_bastion_access" {
  name        = "${var.project_name}-ssm-bastion-access"
  description = "Allows starting an SSM Session Manager port-forwarding session to the ${var.project_name} bastion only"
  policy      = data.aws_iam_policy_document.ssm_bastion_access.json
  tags        = var.tags
}

resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

resource "aws_iam_group_policy_attachment" "ssm_bastion_access" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.ssm_bastion_access.arn
}

resource "aws_iam_group_membership" "developers" {
  name  = "${var.project_name}-developers-membership"
  group = aws_iam_group.developers.name
  users = var.developer_user_names
}
