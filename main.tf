// Simple Web Server so this works 
//CentrifyAWSCLI.py -t deloitte.my
// create the master

provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default=80
}

// external program to be called to get my ip 
data "external" "myip" {
  program = ["python", "myip.py"]
}


// gets the ip and shows it 

resource "null_resource" show_my_ip {
	triggers ={
        build_number = "${timestamp()}"
    }
	provisioner "local-exec" 	{
		command = "echo Current IP  ${data.external.myip.result.IP}"
	}
}



// I need to create a bunch of slaves first			
resource "aws_instance" "kube_slave" {

	// redhat 7.0 - once we install selinux it will come to 7.6
	// below is a prepackaged image
	//ami = "ami-a8d369c0" -- with se linux
	// ami = "ami-09442709a87042d8a" // with se linux and dos to unix
	//ami = "ami-0acece2f2b3c0b372" // everything with docker
	ami = "ami-0c55b159cbfafe1f0" //bionic

	// 2 CPU 4 GB memory
	instance_type = "t2.large" 
	
	// standard subnet on VPC
	subnet_id = "${aws_subnet.cluster_subnet.id}" 
	
	associate_public_ip_address = true
	
	key_name = "ohio-K8"
	
	// number of slaves
	count = 2

	tags = {
		Name= "kube_slave_v2_${count.index}"
	}
	
	timeouts {
		create = "2h"
		delete = "2h"
	}
  
	vpc_security_group_ids = ["sg-0296fca1ed6c17681"]

	
	
	// create a directory called kube in home
	 user_data = <<EOF
			sudo apt-get install -y dos2unix
			sudo mkdir $HOME/kube
			sudo chmod 777 kube
			sudo echo "Made it" > $HOME/kube/success.txt
		EOF

	// push the bash to installing everything
	provisioner "file" 	{
		source      = "/${path.module}/installkbase.sh"
		destination = "/home/ubuntu/installkbase.sh"
	}

	// push the bash for starting kubeadm
	provisioner "file" 	{
		source      = "${path.module}/startkubeadm.sh"
		destination = "/home/ubuntu/startkubeadm.sh"
	}
	 
	/* 
	// Default t2.large is 10GB and that is not enough. Giving it 50GB
	root_block_device 	{
		volume_size = 50
    
    */

	// start of by running the install 
	// I dont need to start kubeadm in slaves
  	provisioner "remote-exec" {
	
		inline = [
		  "chmod +x /home/ubuntu/*.sh",
		  "dos2unix *.sh",
		  "/home/ubuntu/installkbase.sh"
		]
	}

	// give it the SSH connection details
	connection 	{
		type     = "ssh"
		user     = "ubuntu"
		host =  "${self.private_ip}"
		password = ""
		private_key = ""
		agent = "true"
	}

}

output "slaves"{
	value = "${aws_instance.kube_slave.*.private_ip}"
}

resource "local_file" "write_sl" {
	content = "${jsonencode(aws_instance.kube_slave.*.private_ip)}"
	filename = "${path.module}/slaves.txt"
}

// create this as one ip per line
// this will generate a file called slave_ip.txt - which I can ship over
data "external" "write_slave" {
  depends_on = ["aws_instance.kube_slave"]
  program = ["python", "${path.module}/genslave.py"]
  query = {
		json_data = "${jsonencode(aws_instance.kube_slave.*.private_ip)}"
	}
}


// create the master
resource "aws_instance" "kube-master" {

	// redhat 7.0 - once we install selinux it will come to 7.6
	// below is a prepackaged image
	//ami = "ami-a8d369c0" 
	//ami = "ami-09442709a87042d8a" // with se linux and dos to unix
	//ami = "ami-0acece2f2b3c0b372" // everything with docker
        ami = "ami-0c55b159cbfafe1f0" //ubunut
	
    
        // 2 CPU 8 GB memory
	instance_type = "t2.large" 
	
	// standard subnet on VPC
	//subnet_id = "subnet-625bdf05" 

	// standard subnet on VPC
	subnet_id = "${aws_subnet.cluster_subnet.id}" 
	
	associate_public_ip_address = true
	
	key_name = "ohio-K8"

	tags =	{
		Name = "KubeMaster1_v2"
	}
	
	timeouts 	{
		create = "2h"
		delete = "2h"
	}
  
	vpc_security_group_ids = ["sg-0296fca1ed6c17681"]
	
	// create a directory called kube in home
	 user_data = <<EOF
			sudo apt-get install -y dos2unix
			sudo mkdir $HOME/kube
			sudo chmod 777 kube
			sudo echo "hello" > success.txt
		EOF

	
	// push the bash to installing everything
	provisioner "file" 	{
		source      = "${path.module}/installkbase.sh"
		destination = "/home/ubuntu/installkbase.sh"
	}

	// push the bash for starting kubeadm
	provisioner "file" 	{
		source      = "${path.module}/startkubeadm.sh"
		destination = "/home/ubuntu/startkubeadm.sh"
	}

	// push the file for starting slaves
	provisioner "file" 	{
		source      = "${path.module}/start_slave.sh"
		destination = "/home/ubuntu/start_slave.sh"
	}

	// push the file that has all the slave IP
	provisioner "file" 	{
		source      = "${path.module}/slave_ip.txt"
		destination = "/home/ubuntu/slave_ip.txt"
	}
	
	// start of by running the install 
  	provisioner "remote-exec" {
	
		inline = [
		  "chmod +x /home/ubuntu/*.sh",
		  "dos2unix *.sh",
		  "/home/ubuntu/installkbase.sh",
		  "/home/ubuntu/startkubeadm.sh",
		  "/home/ubuntu/start_slave.sh"

		]
	}

	// give it the SSH connection details
	connection 	{
		type     = "ssh"
		user     = "ubuntu"
		host =  "${aws_instance.kube-master.private_ip}"
		password = ""
		private_key = ""
		agent = "true"
	}
	
  
 
	// Default t2.medium is 10GB and that is not enough. Giving it 50GB
	root_block_device 	{
		volume_size = 50
    }

	depends_on = ["aws_instance.kube_slave"] //, "data.external.write_slave"]

  }

 

