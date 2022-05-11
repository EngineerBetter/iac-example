resource "aws_ecr_repository" "foo" {
  name                 = "test-repository"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecr_repository" "foo" {
  name                 = "test-repository"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}


resource "aws_ecr_repository" "repository" {
  name                 = "test-repository"
  image_tag_mutability = "MUTABLE"
  tags = {
    Name = "test-repository"
  }
}

resource "aws_ebs_volume" "web_host_storage" {
  availability_zone = "ap-southeast-2"
  encrypted         = false
  size = 1
  tags = {
    Name = "abcd-ebs"
  }
}
