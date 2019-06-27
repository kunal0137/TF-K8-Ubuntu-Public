
// by default - I am giving 30 machines



resource "aws_subnet" "cluster_subnet" {
  vpc_id     = "vpc-4a86b422"
  cidr_block = "172.31.51.0/24" // moveing away from 20 going to give less IP

  tags = {
    Name = "K8_subnet_2"
      }
}


