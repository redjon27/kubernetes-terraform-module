bucket         = "redi-terraform-state"
key            = "eks/dev/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true