resource "aws_instance" "swarm-manager" {
    ami = "ami-1a6cc07a"
    instance_type = "t2.small"
    count = "${var.cluster_manager_count}"
    associate_public_ip_address = "true"
    key_name = "foo"
    subnet_id = "${aws_subnet.a.id}"
    vpc_security_group_ids      = [
      "${aws_security_group.swarm.id}"
    ]

    root_block_device = {
      volume_size = 100
    }

    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/foo")}"
      agent = false
    }

    tags {
      Name = "${var.vpc_key}-manager-${count.index}"
      VPC = "${var.vpc_key}"
      Terraform = "Terraform"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo docker swarm init"
      ]
    }

    depends_on = [
      "aws_instance.bastion"
    ]
}

resource "aws_instance" "swarm-node" {
    ami = "ami-1a6cc07a"
    instance_type = "t2.small"
    count = "${var.cluster_node_count}"
    associate_public_ip_address = "true"
    key_name = "foo"
    subnet_id = "${aws_subnet.a.id}"
    vpc_security_group_ids = [
      "${aws_security_group.swarm.id}"
    ]

    root_block_device = {
      volume_size = 100
    }

    connection {
      user = "ubuntu"
      private_key = "${file("~/.ssh/foo")}"
      agent = false
    }

    tags {
      Name = "${var.vpc_key}-node-${count.index}"
      VPC = "${var.vpc_key}"
      Terraform = "Terraform"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo docker swarm join ${aws_instance.swarm-manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.swarm-manager.0.private_ip} swarm join-token -q worker)"
      ]
    }

    depends_on = [
      "aws_instance.swarm-manager"
    ]
}

resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${join(",", aws_instance.swarm-node.*.id)}"
  }

  connection {
    host = "${aws_instance.bastion.public_dns}"
    user = "ubuntu"
    private_key = "${file("~/.ssh/deis")}"
    agent = false
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
      "docker -H ${element(aws_instance.swarm-manager.*.private_ip, 0)}:2375 network create --driver overlay appnet",
      "docker -H ${element(aws_instance.swarm-manager.*.private_ip, 0)}:2375 service create --name nginx --publish 80:80 --network appnet nginx"
    ]
  }
}

output "swarm_managers" {
  value = "${concat(aws_instance.swarm-manager.*.public_dns)}"
}

output "swarm_nodes" {
  value = "${concat(aws_instance.swarm-node.*.public_dns)}"
}
