resource "aws_ecr_repository" "ptodo_backend" {
  name = "ptodo/backend"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ptodo_frontend" {
  name = "ptodo/frontend"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ptodo_backend" {
  repository = aws_ecr_repository.ptodo_backend.name

  policy = <<EOF
  {
    "rules" : [
      {
        "rulePriority": 1,
        "description": "Keep last 30 release tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["release"],
          "countType": "imageCountMoreThan",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}

resource "aws_ecr_lifecycle_policy" "ptodo_frontend" {
  repository = aws_ecr_repository.ptodo_frontend.name

  policy = <<EOF
  {
    "rules" : [
      {
        "rulePriority": 1,
        "description": "Keep last 30 release tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["release"],
          "countType": "imageCountMoreThan",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}
