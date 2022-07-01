terraform {
  backend "s3" {
    bucket      = "my-ggn-bucket"
    key         = "Team3/tfstate.tf"
    region      = "us-west-1"
    encrypt     = true
  }
}
