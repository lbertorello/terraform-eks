provider "aws" {
  profile = "<PROFILE>"

  assume_role {
    role_arn = "arn:aws:iam::<ACCOUNT-ID>:role/Terraformers"
  }
}