output "ecr_repository_url" {
  description = "The URL to point ECS at to find Docker images"
  value = aws_ecr_repository.ecr_repository.repository_url
}