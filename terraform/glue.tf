############################################
# IAM
############################################

resource "aws_iam_role" "glue_crawler_role" {
  name = "analytics_glue_crawler_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "glue_crawler_role_policy" {
  name   = "analytics_glue_crawler_role_policy"
  role   = aws_iam_role.glue_crawler_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetBucketAcl",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::imyjer-manifold-data"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:/aws-glue/*"
      ]
    }
  ]
}
EOF

}

############################################
# Glue Crawler and Database
############################################

resource "aws_glue_catalog_database" "manifold-db" {
  name = "imyjer-manifold-db"
}

resource "aws_glue_crawler" "manifold_crawler" {
  database_name = aws_glue_catalog_database.manifold-db.name
  name          = "manifold-glue-crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  # schedule = "cron(* * * * ? *)"

  # configuration = "{\"Version\": 1.0, \"CrawlerOutput\": { \"Partitions\": { \"AddOrUpdateBehavior\": \"InheritFromTable\" }, \"Tables\": {\"AddOrUpdateBehavior\": \"MergeNewColumns\" } } }"

  s3_target {
    path = "s3://${aws_s3_bucket.data_bucket.bucket}/data/"
  }
}

resource "aws_glue_catalog_table" "manifold-table" {
  name          = "manifold_table"
  database_name = aws_glue_catalog_database.manifold-db.name

  # partition_keys {
  #   name = "timestamp"
  # }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_bucket.bucket}/data/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "manifold-serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"

      parameters = {
        paths = "first_name,last_name,middle_name,zip_code,timestamp"
      }
    }

    columns {
      name = "first_name"
      type = "string"
    }

    columns {
      name = "middle_name"
      type = "string"
    }

    columns {
      name = "last_name"
      type = "string"
    }

    columns {
      name = "zip_code"
      type = "string"
    }

    columns {
      name = "timestamp"
      type = "timestamp"
    }

    stored_as_sub_directories = "false"
  }

  parameters = {
    classification     = "json"
    typeOfData         = "file"
    UPDATED_BY_CRAWLER = "manifold-glue-crawler"
    compressionType    = "none"
  }
}

