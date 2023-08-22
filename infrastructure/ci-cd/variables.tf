variable "iam_policy_arn_ci_cd_user" {
  description = "IAM Policy to be attached to ecs task role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
    "arn:aws:iam::aws:policy/AWSAppRunnerServicePolicyForECRAccess",
    "arn:aws:iam::aws:policy/AWSECRPullThroughCache_ServiceRolePolicy",
    "arn:aws:iam::aws:policy/ECRReplicationServiceRolePolicy",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess",
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",
  ]
}
