data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "cluster" {
  name = "${var.prefix}-eks-cluster"
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.cluster.version}/amazon-linux-2/recommended/release_version"
}