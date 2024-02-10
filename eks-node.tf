# # EKS Node
resource "aws_security_group" "node" {
  name        = "${var.prefix}-eks-node-sg"
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
    Name = "${var.prefix}-eks-node-sg"
  }
}

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.cluster.name
  version         = aws_eks_cluster.cluster.version
  ami_type        = "AL2_x86_64"
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  node_group_name = "${var.prefix}-eks-node"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.medium"]
  capacity_type   = "SPOT"

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    min_size     = 3
    desired_size = 3
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node
  ]
}

resource "aws_launch_template" "node" {
  name_prefix = "${var.prefix}-eks-node-"
  description = "Amazon EKS managed nodes"

  ebs_optimized          = true
  update_default_version = true

  vpc_security_group_ids = [aws_security_group.node.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 30
      volume_type           = "gp3"
    }
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-eks-node"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.prefix}-eks-node"
    }
  }
}