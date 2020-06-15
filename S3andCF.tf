	//Authenticate Yourself
provider "aws" {
	region                  = "ap-south-1"      //Select your region 
  	profile= "KAY"	        //Select your profileName
}

	//Create an S3 bucket

resource "aws_s3_bucket" "bucket"{
	bucket = "mybasic8274"          //Bucket name should be unique in region i.e. in ap-south-1 there can only be one bucket named mybasic8274
	acl = "private"
	force_destroy = "true"
	versioning {
		enabled = "true"
	}
}

resource "null_resource" "Clone"{

	depends_on = [aws_s3_bucket.bucket]

	provisioner "local-exec"{		
		command = "git clone https://github.com/kanishkagarwal2000/SampleBasicSite"
	}
}

	//Adding image in s3

resource "aws_s3_bucket_object" "add_to_bucket"{
	depends_on = [aws_s3_bucket.bucket,null_resource.Clone]
	bucket = aws_s3_bucket.bucket.id
	source = "SampleBasicSite/index.jpg" // enter source of the file you wanna add
	key = "image.jpg" // enter the name u want to give to your file 
	acl = "public-read"  // it is important to make the file accessible by all
}

	//Creatng Cloudfront
resource "aws_cloudfront_distribution" "cfront"{
	depends_on = [aws_s3_bucket.bucket , null_resource.Clone , aws_s3_bucket_object.add_to_bucket]
	origin{
		domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
		origin_id = "message"   	//can choose according to your choice
		custom_origin_config{
			http_port = 80
			https_port = 80
			origin_protocol_policy = "match-viewer"
			origin_ssl_protocols = ["TLSv1","TLSv1.1","TLSv1.2"]
		}
	}
	enabled = "true"
	default_cache_behavior{
		allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
		cached_methods = ["GET","HEAD"]
		target_origin_id = "message"  
		forwarded_values{
			query_string = "false"
			cookies{
				forward = "none"
			}
		}
		viewer_protocol_policy = "allow-all"
		min_ttl = 0
		default_ttl = 3600
		max_ttl = 86400
	}
	restrictions{
		geo_restriction{
			restriction_type = "none"
		}
	}
	viewer_certificate{
		cloudfront_default_certificate = "true"
	}
}


output "domain-name"{
	value = aws_cloudfront_distribution.cfront.domain_name
}