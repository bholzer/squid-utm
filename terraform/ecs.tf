/*====
ECS cluster
======*/
resource "aws_ecs_cluster" "main" {
  count = var.cluster_id == "" ? 1 : 0 # Do not create another cluster if one is provided
  name = "${var.environment}-${var.name}"

  tags = merge(
    var.tags,
    map("Name", "${var.environment}-${var.name}"),
  )
}

/*====
ECS task definitions
======*/

resource "aws_cloudwatch_log_group" "cwlog" {
  name              = "/ecs/${var.environment}-${var.name}"
  retention_in_days = 30

  tags = merge(
    var.tags,
    map("Name",  format("%s-%s", var.environment, var.name)),
  )
}


resource "aws_ecs_task_definition" "squid" {
  family = "${var.environment}-${var.name}"

  container_definitions = <<EOF
[
  {
    "name": "${var.name}",
    "image": "${var.squid_image}",
    "essential": true,
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "/ecs/${var.environment}-${var.name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "ecs"
        }
    },
    "cpu": 0,
    "environment": [
      {
        "name": "ALLOWED_CIDRS",
        "value": "${var.allowed_cidrs}"
      },
      {
        "name": "AWS_REGIONS",
        "value": "${var.whitelist_aws_region}"
      },
      {
        "name": "SQUID_WHITELIST",
        "value": "${var.whitelist_url}"
      },
      {
        "name": "SQUID_BLACKLIST",
        "value": "${var.blacklist_url}"
      },
      {
        "name": "SQUID_BLOCKALL",
        "value": "${var.url_block_all}"
      }
    ],
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${var.port},
        "hostPort": ${var.port}        
      }
    ],
    "mountPoints" : [],
    "volumesFrom" : []
  }
]
EOF

  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn = aws_iam_role.ecs_execution_role.arn
  tags = merge(
    var.tags,
    map("Name",  format("%s-%s-task", var.environment, var.name)),
  )
}

resource "aws_ecs_service" "service" {
  name = "${var.environment}-${var.name}"
  cluster = var.cluster_id == "" ? aws_ecs_cluster.main.id : var.cluster_id
  task_definition = "${aws_ecs_task_definition.squid.family}:${aws_ecs_task_definition.squid.revision}"
  launch_type = "FARGATE"
  desired_count = var.desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name = var.name
    container_port = var.port
  }

  network_configuration {
    subnets = var.task_subnets
    security_groups = [aws_security_group.fargate.id]
    assign_public_ip = true
  }

  depends_on = [
    "aws_lb.main",
    "aws_ecs_task_definition.squid",
  ]
}
