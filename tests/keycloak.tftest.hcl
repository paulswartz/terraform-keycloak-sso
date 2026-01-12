mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  mock_resource "aws_alb" {
    defaults = {
      id  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/keycloak/50dc6c495c0c9188"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/keycloak/50dc6c495c0c9188"
    }
  }
  
  mock_resource "aws_lb_target_group" {
    defaults = {
      id  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/keycloak/73e2d6bc24d8a067"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/keycloak/73e2d6bc24d8a067"
    }
  }

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/keycloak-role"
    }
  }

  mock_resource "aws_lb_listener" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/keycloak/50dc6c495c0c9188/804040a454cc76a0"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/keycloak-policy"
    }
  }

  mock_resource "aws_appautoscaling_policy" {
    defaults = {
      arn = "arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:12345678-1234-1234-1234-123456789012:resource/ecs/service/cluster/service:policyName/keycloak-policy"
    }
  }
}

variables {
  aws_region      = "us-east-1"
  aws_jms_queues  = "queue1"
  db_name         = "keycloak"
  db_username     = "keycloak_user"
  environment     = "test"
  kc_username     = "admin"
  organization    = "example"
  private_subnets = ["subnet-private1", "subnet-private2"]
  public_subnets  = ["subnet-public1", "subnet-public2"]
  vpc_id          = "vpc-123456"
  is_temporary    = true

  autoscale = {
    scale_down_comparison_operator = "LessThanThreshold"
    scale_down_threshold           = "20"
    evaluation_periods             = "2"
    metric_name                    = "CPUUtilization"
    scale_up_comparison_operator   = "GreaterThanThreshold"
    scale_up_threshold             = "80"
    adjustment_type                = "ChangeInCapacity"
    cooldown                       = "60"
    scale_down_adjustment          = "-1"
    scale_up_adjustment            = "1"
  }
}

run "unit_test" {
  command = plan

  assert {
    condition     = aws_ecs_cluster.keycloak-cluster[0].name == "keycloak-test-cluster"
    error_message = "Cluster name did not match expected 'keycloak-test-cluster'"
  }

  assert {
    condition     = aws_db_instance.keycloak-database-engine.identifier == "keycloak-test"
    error_message = "DB identifier did not match expected 'keycloak-test'"
  }

  assert {
    condition     = aws_db_instance.keycloak-database-engine.backup_retention_period == 0
    error_message = "Backup retention period should be 0 when is_temporary is true"
  }

  assert {
    condition     = aws_secretsmanager_secret.keycloak-admin-password.recovery_window_in_days == 0
    error_message = "Admin password recovery window should be 0 when is_temporary is true"
  }

  assert {
    condition     = aws_secretsmanager_secret.keycloak-database-password.recovery_window_in_days == 0
    error_message = "Database password recovery window should be 0 when is_temporary is true"
  }
}

run "non_temporary_resources" {
  command = plan

  variables {
    is_temporary            = false
    backup_retention_period = 7
    log_driver              = "splunk"
  }

  assert {
    condition     = aws_secretsmanager_secret.keycloak-admin-password.recovery_window_in_days == 30
    error_message = "Admin password recovery window should be 30 days for non-temporary resources"
  }

  assert {
    condition     = aws_secretsmanager_secret.keycloak-database-password.recovery_window_in_days == 30
    error_message = "Database password recovery window should be 30 days for non-temporary resources"
  }

  assert {
    condition     = aws_db_instance.keycloak-database-engine.backup_retention_period == 7
    error_message = "Backup retention period should match variable when is_temporary is false"
  }

  assert {
    condition     = aws_secretsmanager_secret.keycloak-splunk-token[0].recovery_window_in_days == 30
    error_message = "Splunk token recovery window should be 30 days for non-temporary resources"
  }
}

run "jms_queues" {
  command = plan

  variables {
    aws_jms_queues = "queue_one,queue_two"
  }

  assert {
    condition     = strcontains(aws_ecs_task_definition.keycloak-ecs-taskdef.container_definitions, "-DawsJmsQueues=queue_one,queue_two")
    error_message = "Task definition did not contain expected JMS queues configuration"
  }
}

run "admin_cidrs_configuration" {
  command = plan

  variables {
    admin_cidrs = ["10.0.0.1/32"]
  }

  assert {
    condition     = length(aws_lb_listener_rule.forward_admin_from_cidrs) == 1
    error_message = "Expected 1 admin forwarding rule when admin_cidrs is set"
  }

  assert {
    condition     = length(aws_lb_listener_rule.redirect_admin_from_other_cidrs) == 1
    error_message = "Expected 1 admin redirect rule when admin_cidrs is set"
  }
}
