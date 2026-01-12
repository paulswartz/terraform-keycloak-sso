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
}
