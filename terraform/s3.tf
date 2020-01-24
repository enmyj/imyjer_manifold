
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.data_bucket}"
  acl = "private"
}
