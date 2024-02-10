# EKS Cluster
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.prefix}-eks-cluster/cluster"
  retention_in_days = 7
}

resource "aws_security_group" "cluster" {
  name        = "${var.prefix}-eks-cluster-sg"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-eks-cluster-sg"
  }
}

resource "aws_eks_cluster" "cluster" {
  name                      = "${var.prefix}-eks-cluster"
  role_arn                  = aws_iam_role.cluster.arn
  version                   = "1.28"
  enabled_cluster_log_types = []

  vpc_config {
    subnet_ids              = module.vpc.public_subnets
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_cloudwatch_log_group.cluster,
    aws_iam_role_policy_attachment.cluster
  ]
}

# AdminFullAccess
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  user_name     = "AdminFullAccess"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AdminFullAccess"

  depends_on = [aws_eks_cluster.cluster]
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.admin.principal_arn

  access_scope {
    type = "cluster"
  }
}

# Terraformers
resource "aws_eks_access_entry" "terraform" {
  cluster_name  = aws_eks_cluster.cluster.name
  user_name     = "Terraformers"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraformers"

  depends_on = [aws_eks_cluster.cluster]
}

resource "aws_eks_access_policy_association" "terraform" {
  cluster_name  = aws_eks_cluster.cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.terraform.principal_arn

  access_scope {
    type = "cluster"
  }
}

# EC2PrivateDNSName
resource "aws_eks_access_entry" "node" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.node.arn
  type          = "EC2_LINUX"

  depends_on = [aws_eks_cluster.cluster]
}

# OIDC
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}