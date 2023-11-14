# Crea un clúster de EKS
resource "aws_eks_cluster" "cluster_eks" {
  name     = "eks-cluster-proto"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_vpc.vpc_eks.id 
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}

# Crea un rol de IAM para el clúster de EKS
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-proto-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Adjunta una política de IAM al rol del clúster de EKS
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Crea un grupo de seguridad para el clúster de EKS
resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-cluster-group"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configura kubectl para el clúster de EKS
data "aws_eks_cluster_auth" "eks_cluster" {
  name = aws_eks_cluster.cluster_eks.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster_auth.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster_auth.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}

# Crea un balanceador de carga de aplicaciones (ALB)
resource "aws_lb" "app_lb" {
  name               = "lb-eks"
  internal           = false
  load_balancer_type = "application"

  subnets = aws_subnet.private_subnet.id

  security_groups = [
    aws_security_group.app_lb.id,
  ]

  tags = {
    Name = "lb-eks"
  }
}

# Crea un grupo de seguridad para el balanceador de carga de aplicaciones (ALB)
resource "aws_security_group" "app_lb" {
  name_prefix = "app-lb-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Crea un servicio para exponer la aplicación a través del balanceador de carga de aplicaciones (ALB)
resource "kubernetes_service" "app_service" {
  metadata {
    name      = "my-app-service"
    namespace = "default"
    labels = {
      app = "my-app"
    }
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-internal"= "false"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"= "http"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled"= "true"
      "service.beta.kubernetes.io/aws-load-balancer-extra-security-groups"= "${aws_security_group.app_lb.id}"
      # Configura otros parámetros del balanceador de carga de aplicaciones, si es necesario
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.app_deployment.metadata[0].labels.app
    }

    port {
      name       = "http"
      port       = 50051
      target_port= 50051
      protocol   = "TCP"
    }

    type                = "LoadBalancer"
    load_balancer_ip    = aws_lb.app_lb.dns_name
    external_traffic_policy= "Local"
    session_affinity    = "None"
    # Configura otros parámetros del servicio, si es necesario
  }
}

# Crea un deployment para la aplicación en el clúster de EKS
resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name      = "my-app-deployment"
    namespace = "default"
    labels = {
      app = "my-app"
    }
  }

  spec {
    replicas       = 2
    selector {
      match_labels = {
        app = kubernetes_deployment.app_deployment.metadata[0].labels.app
      }
    }

    template {
      metadata {
        labels = kubernetes_deployment.app_deployment.metadata[0].labels
      }

      spec {
        container {
          image   = "nginx:latest"
          name    = "proto-grpc"

          port {
            container_port = 51051
          }

          # Configura otros parámetros del contenedor, si es necesario
        }

        # Configura otros parámetros del pod, si es necesario
      }
    }

    # Configura otros parámetros del deployment, si es necesario
  }
}
