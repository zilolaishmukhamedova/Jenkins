
#Creating S3bucket
resource "aws_s3_bucket" "purple" {
  bucket = "purple"
}
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.bucket.bucket
  rule {
    id = "log"
    expiration {
      days = 90
    }
    filter {
      and {
        prefix = "log/"
        tags = {
          rule      = "log"
          autoclean = "true"
        }
      }
    }
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
  rule {
    id = "tmp"
    filter {
      prefix = "tmp/"
    }
    expiration {
      date = "2023-01-13T00:00:00Z"
    }
    status = "Enabled"
  }
}



versioning_configuration {
  status = "Enabled"
}

resource "aws_s3_bucket_lifecycle_configuration" "versioning-bucket-config" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.versioning]
  bucket     = aws_s3_bucket.versioning_bucket.bucket
  rule {
    id = "config"
    filter {
      prefix = "config/"
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }
    status = "Enabled"
  }
}







# route53domains registered domain

# resource "aws_route53domains_registered_domain" "gogreen_aws" {
#   domain_name = "www.gogreen.com"

# }

#Create route53_zone

resource "aws_route53_zone" "gogreen_aws" {
  name = "www.gogreen.com"


  tags = {
    Environment = "dev"
  }
}
# Creating EIP
resource "aws_eip" "eip_r53" {
  vpc = true
}


resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.gogreen_aws.zone_id
  name    = "www.gogreen.com"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip_r53.public_ip]
}

# # Creating cloudfront_distribution

# resource "aws_cloudfront_distribution" "s3_distribution" {
#   origin {
#     domain_name = aws_s3_bucket.a.bucket_regional_domain_name
#     origin_id   = aws_s3_bucket.a.id

#     s3_origin_config {
#       origin_access_identity = "origin-access-identity/cloudfront/ABCDEFG1234567"
#     }
#   }

#   enabled = true
#   #is_ipv4_enabled     = true
#   comment             = "Some comment"
#   default_root_object = "index.html"

#   logging_config {
#     include_cookies = false
#     bucket          = "mylogs.s3.amazonaws.com"
#     prefix          = "myprefix"
#   }

#   #aliases = ["mysite.example.com", "yoursite.example.com"]

#   default_cache_behavior {
#     allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = aws_s3_bucket.a.id

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }

#     viewer_protocol_policy = "allow-all"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }

#   # Cache behavior with precedence 0
#   ordered_cache_behavior {
#     path_pattern     = "/content/immutable/*"
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id = aws_s3_bucket.a.id

#     forwarded_values {
#       query_string = false
#       headers      = ["Origin"]

#       cookies {
#         forward = "none"
#       }
#     }

# min_ttl                = 0
# default_ttl            = 86400
# max_ttl                = 31536000
# compress               = true
# viewer_protocol_policy = "redirect-to-https"


# # Cache behavior with precedence 1
# ordered_cache_behavior {
#   path_pattern     = "/content/*"
#   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#   cached_methods   = ["GET", "HEAD"]
#   target_origin_id = aws_s3_bucket.a.id

#   forwarded_values {
#     query_string = false

#     cookies {
#       forward = "none"
#     }
#   }

#   min_ttl                = 0
#   default_ttl            = 3600
#   max_ttl                = 86400
#   compress               = true
#   viewer_protocol_policy = "redirect-to-https"
# }

# price_class = "PriceClass_200"

# restrictions {
#   geo_restriction {
#     restriction_type = "whitelist"
#     locations        = ["US", "CA", "GB", "DE"]
#   }
# }

# tags = {
#   Environment = "production"
# }

# viewer_certificate {
#   cloudfront_default_certificate = true
# }
