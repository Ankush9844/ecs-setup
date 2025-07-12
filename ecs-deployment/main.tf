module "vpc" {
  source       = "../modules/vpc"
  project_name = var.project_name
  cidr_block   = var.cidr_block
}

module "securityGroups" {
  source       = "../modules/security-group"
  project_name = var.project_name
  vpc_id       = module.vpc.vpcID
}

module "alb" {
  source             = "../modules/alb"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpcID
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.securityGroups.alb_sg_id
}

# module "ecsOnFargate" {
#   source               = "../modules/ecs-fargate"
#   project_name         = var.project_name
#   vpc_id               = module.vpc.vpcID
#   container_image      = var.container_image
#   public_subnet_ids    = module.vpc.public_subnet_ids
#   alb_target_group_arn = module.alb.alb_target_group_arn
#   ecs_task_sg_id       = module.securityGroups.ecs_task_sg_id
#   depends_on           = [module.vpc, module.alb]
# }

module "ecsOnEC2" {
  source                 = "../modules/ecs-ec2"
  project_name           = var.project_name
  ecs_task_sg_id         = module.securityGroups.ecs_task_sg_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  alb_target_group_2_arn = module.alb.alb_target_group_2_arn
  container_image        = var.container_image
  ecs_security_group_id  = module.securityGroups.ecs_security_group_id
  depends_on             = [module.securityGroups]
}
