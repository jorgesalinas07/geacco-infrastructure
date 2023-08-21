module "Load_balancer" {
  source = "../../modules/alb"
  security_group_name = "ALB_security_group"
  vpc_id = "" // to be filled out
  my_ip = "" // to be filled out
  lb_target_group_name = "geacco-alb-target-group"
  lb_name = "geacco-ALB"
  load_balancer_type = "application"
  lb_security_groups = [""] // to be filled out
  lb_subnets = [""] // to be filled out
}
