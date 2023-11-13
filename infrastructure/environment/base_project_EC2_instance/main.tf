module "base_project_EC2_instance" {
  source = "../../modules/ec2"
  ec2_name = "geacco-app-bucket"
  vpc_id = "" // to be filled out
  my_ip = "" // to be filled out
}