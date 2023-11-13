module "elastic_cache" {
  source = "../../modules/aec"
  ec_name = "geacco_app_EC"
  vpc_id = "" // to be filled out
  ec_security_groups = [""] // to be filled out
  replication_group_id = "" // to be filled out
  subnet_id = [""] // to be filled out 

}