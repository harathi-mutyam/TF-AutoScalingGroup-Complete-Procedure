resource "aws_key_pair" "asg_key" {
  key_name   = "asgkey"
  public_key =file("asgkey.pub") # base64encode(file("asgkey.pub"))
}
