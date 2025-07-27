module "vpc" {
  source      = "../modules/vpc"
  ProjectName = var.ProjectName
  cidrBlock   = var.cidrBlock
}

module "securityGroups" {
  source      = "../modules/security-groups"
  ProjectName = var.ProjectName
  vpcID       = module.vpc.vpcID
}

module "appLoadBalancer" {
  source                         = "../modules/alb"
  ProjectName                    = var.ProjectName
  vpcID                          = module.vpc.vpcID
  PublicSubnetIDs                = module.vpc.PublicSubnetIDs
  appLoadBalancerSecurityGroupID = module.securityGroups.appLoadBalancerSecurityGroupID
  defaultSSLCertificateARN       = var.defaultSSLCertificateARN
  frontendDomain                 = var.frontendDomain
  backendDomain                  = var.backendDomain
}

module "ecsOnFargate" {
  source                            = "../modules/ecs-fargate"
  ProjectName                       = var.ProjectName
  ecsFargateSecurityGroupFrontendID = module.securityGroups.ecsFagateSecurityGroupFrontendID
  ecsFargateSecurityGroupBackendID  = module.securityGroups.ecsFargateSecurityGroupBackendID
  fargateTargetGroupFrontendARN     = module.appLoadBalancer.fargateTargetGroupFrontendARN
  fargateTargetGroupBackendARN      = module.appLoadBalancer.fargateTargetGroupBackendARN
  PublicSubnetIDs                   = module.vpc.PublicSubnetIDs
  containerImage                    = var.containerImage
  containerImageBackend             = var.containerImageBackend
  backendDomain                     = var.backendDomain
  depends_on                        = [module.vpc, module.appLoadBalancer]
}

# module "ecsOnEC2" {
#   source             = "../modules/ecs-ec2"
#   ProjectName        = var.ProjectName
#   ec2TargetGroupARN  = module.appLoadBalancer.ec2TargetGroupARN
#   ecsSecurityGroupID = module.securityGroups.ecsEC2SecurityGroupID
#   PublicSubnetIDs    = module.vpc.PublicSubnetIDs
#   KeyName            = var.KeyName
#   InstanceType       = var.InstanceType
#   ContainerImage     = var.ContainerImage
#   depends_on         = [module.vpc, module.appLoadBalancer, module.securityGroups]
# }

module "codeBuildProject" {
  source           = "../modules/pipeline/codebuild"
  github_token     = var.github_token
  account_id       = var.account_id
  aws_region       = var.aws_region
  githubConnection = var.githubConnection
}

module "chatappPipeline" {
  source                   = "../modules/pipeline/codepipeline"
  aws_region               = var.aws_region
  account_id               = var.account_id
  ecsClusterName           = module.ecsOnFargate.ecsClusterName
  ecsFrontendServiceName   = module.ecsOnFargate.ecsFrontendServiceName
  ecsBackendServiceName    = module.ecsOnFargate.ecsBackendServiceName
  githubConnection         = var.githubConnection
  codeBuildFrontendProject = module.codeBuildProject.codeBuildFrontendProject
  codeBuildBackendProject  = module.codeBuildProject.codeBuildBackendProject
  depends_on               = [module.codeBuildProject]
}
