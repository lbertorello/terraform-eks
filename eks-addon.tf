# CoreDNS
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "coredns"
  addon_version = data.aws_eks_addon_version.coredns.version
}