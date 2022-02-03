terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "iiab-terraform-state"
    key    = "ecs/terraform.tfstate"
    // Make this configurable
    region = "us-east-2"

    dynamodb_table = "iiab-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

// Is this better handled via directly accessing the ecr_repository?
data "terraform_remote_state" "ecr_repository" {
  backend = "s3"

  config = {
    // Make this configurable
    bucket = "iiab-terraform-state"
    key = "ecr/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    // Make this configurable
    bucket = "iiab-terraform-state"
    key = "network/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_iam_user" "terraform_aws_user" {
  name = "terraform"
}

// ECS stuff requires AmazonECS_FullAccess
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "iiab-cluster"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_ecs_task_definition" "iiab_task" {
  family                = "iiab-task"
  container_definitions = <<DEFINITION
    [
      {
        "name": "iiab-task",
        "image": "${data.terraform_remote_state.ecr_repository.outputs.ecr_repository_url}",
        "essential": true,
        "portMappings": [
          {
            "containerPort": 80,
            "hostPort": 80
          }
        ],
        "memory": 512,
        "cpu": 256
      }
    ]
    DEFINITION
  // Does Fargate make the most sense for us?
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  memory = 512
  cpu = 256
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role = aws_iam_role.ecsTaskExecutionRole.name
}

resource "aws_security_group" "ecs_service_security_group" {
  name = "ecs-security-group"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "iiab_ecs_service" {
  name = "iiab-ecs-service"
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.iiab_task.arn
  launch_type = "FARGATE"
  desired_count = 3

  load_balancer {
    container_name = aws_ecs_task_definition.iiab_task.family
    container_port = 80
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  network_configuration {
    subnets = data.terraform_remote_state.network.outputs.aws_subnet_ids
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_service_security_group.id]
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "iiab_load_balancer" {
  name = "iiab-load-balancer"
  load_balancer_type = "application"
  subnets = data.terraform_remote_state.network.outputs.aws_subnet_ids

  security_groups = [aws_security_group.load_balancer_security_group.id]
}

resource "aws_lb_target_group" "target_group" {
  name = "target-group"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  health_check {
    matcher = "200"
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.iiab_load_balancer.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

// Gotcha: how do we update the image being used in ECS instances in an automated fashion?

// Seems we would like to actually not have the ECR creation linked to everything else, as we would want
// that existing regardless of whether other things are up or not.

// Do we actually want everything in the same script/executable? It would make it harder for projects
// to tweak it for their own needs. --> Handle this in a shell script

// How do we deal with dev vs. prod environments?

/*
Additional things:
- Route53 / DNS


*/