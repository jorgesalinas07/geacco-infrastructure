module "app_bucket" {
  source = "../../modules/s3"
  bucket_name = "geacco-app-bucket"
  bucket_security_group_vpc_id = "" // to be filled out
  bucket_security_groups = [""] // to be filled out
  endpoint_route_table = "" // to be filled out
  

}