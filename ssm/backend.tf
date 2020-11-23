terraform {
  # backend の設定では variable を使えないので直書きする
  backend "s3" {
    region = "ap-northeast-1"
    bucket = "tfstate-ptodo-prod"
    key    = "ssm/terraform.tfstate"
  }
}
