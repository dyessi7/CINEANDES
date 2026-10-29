terraform {
  backend "s3" {
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cineandes"
    use_lockfile         = true
    encrypt              = true
  }
}