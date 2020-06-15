/*		//step 1:Profile setup and authentication

provider "aws" {
	region                  = "ap-south-1"      //Select your region 
  	profile= "KAY"	        //Select your profileName
}*/


		//step 2:Run ec2 instance


		//step 2a:Create a new key pair

resource "tls_private_key" "keyPair" {
	  algorithm = "RSA"
}

resource "aws_key_pair" "key" {
	key_name = "keyTerra"
  	public_key = tls_private_key.keyPair.public_key_openssh


  	depends_on = [ tls_private_key.keyPair ,]
}


		//step 2b:Create a Security Group

resource "aws_security_group" "webTerraPermission" {
  	name        = "webTerraPermission"
  	description = "Giving SSH and HTTP permissions for all Ip"

  	ingress {
    		description = "SSH"
   		 from_port   = 22
   	 	to_port     = 22
   		 protocol    = "tcp"
    		cidr_blocks = ["0.0.0.0/0"]
	}

  	ingress {
    		description = "HTTP"
    		from_port   = 80
    		to_port     = 80
		protocol    = "tcp"
    		cidr_blocks = ["0.0.0.0/0"]
  	}

  	egress {
    		from_port   = 0
    	to_port     = 0
    	protocol    = "-1"
    	cidr_blocks = ["0.0.0.0/0"]
	}

  	tags = {
    		Name = "securityKay"
  	}
}

		//step 2c:Launching an Instance


resource "aws_instance" "myTerraOs" {
  	depends_on = [aws_key_pair.key ,
		      aws_security_group.webTerraPermission]

	ami           = "ami-0447a12f28fddb066"                            //Ami used-Amazon Linux , you can choose according to your requirements
  	instance_type = "t2.micro"
  	key_name=aws_key_pair.key.key_name
  	security_groups=["webTerraPermission"]

  	tags = {
    		Name = "Hello People"
  	}
}


	// Create an ebs volume
resource "aws_ebs_volume" "ebsGeneration" {
  	depends_on=[aws_instance.myTerraOs,]
  	availability_zone = aws_instance.myTerraOs.availability_zone
  	size              = 1

  	tags = {
    		Name = "myEBS"
 	}
}


	//attaching ebs to the instance we created

resource "aws_volume_attachment" "attaching" {
  	depends_on = [aws_instance.myTerraOs,
	        	      aws_ebs_volume.ebsGeneration]

  	device_name = "/dev/sdh"
  	volume_id   = aws_ebs_volume.ebsGeneration.id
  	instance_id = aws_instance.myTerraOs.id	
  	force_detach =true
}

output "myOsIp" {
  value = aws_instance.myTerraOs.public_ip  //will print your instance public ip
}


	//connection to the instance

resource "null_resource" "connection"{
	depends_on = [aws_volume_attachment.attaching]
			
	connection {
		type = "ssh"
		user = "ec2-user"
		private_key = tls_private_key.keyPair.private_key_pem
		host = aws_instance.myTerraOs.public_ip
	}
		//Configuring our Instance
	provisioner "remote-exec"{
		inline =[
					"sudo yum -y install httpd git", 
					"sudo systemctl start httpd",
					"sudo systemctl enable httpd",
					"sudo mkfs.ext4 /dev/xvdh",
					"sudo mount /dev/xvdh /var/www/html",
					"sudo rm -rf /var/www/html/*",
					"sudo git clone https://github.com/kanishkagarwal2000/SampleBasicSite.git /var/www/html/" ,
					"sudo systemctl restart httpd",
				]
	}
}
resource "null_resource" "saveIP"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.myTerraOs.public_ip} > myTerraOsip.txt"
  	}
}

resource "null_resource" "chrome"{
	depends_on = [ null_resource.connection]
	provisioner "local-exec"{
		command = "chrome ${aws_instance.myTerraOs.public_ip}"   
	}

}