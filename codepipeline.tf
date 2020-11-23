data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
    ]
  }
}

module "codepipeline_role" {
  source     = "./modules/iam_role"
  name       = "codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_s3_bucket" "artifact" {
  bucket = "artifact-ptodo"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

data "aws_ssm_parameter" "github_token" {
  name            = "/github/token"
  with_decryption = true
}

resource "aws_codepipeline" "ptodo" {
  name     = "ptodo"
  role_arn = module.codepipeline_role.iam_role_arn

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      output_artifacts = ["Source"]

      configuration = {
        Owner                = "lupinthe14th"
        Repo                 = "ptodo"
        Branch               = "master"
        OAuthToken           = data.aws_ssm_parameter.github_token.value
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]
      configuration = {
        ProjectName = aws_codebuild_project.ptodo.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = 1
      input_artifacts = ["Build"]

      configuration = {
        ClusterName = aws_ecs_cluster.ptodo.name
        ServiceName = aws_ecs_service.ptodo.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
}


resource "aws_codepipeline_webhook" "ptodo" {
  name            = "ptodo"
  target_pipeline = aws_codepipeline.ptodo.name
  target_action   = "Source"
  authentication  = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = "U+PSoDVpeV8398k9fg3e4bcvbTmlmu6J"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

provider "github" {
  organization = "lupinthe14th"
}

resource "github_repository_webhook" "ptodo" {
  repository = "ptodo"

  configuration {
    url          = aws_codepipeline_webhook.ptodo.url
    secret       = "U+PSoDVpeV8398k9fg3e4bcvbTmlmu6J"
    content_type = "json"
    insecure_ssl = false
  }

  events = ["push"]
}
