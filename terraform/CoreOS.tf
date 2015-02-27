variable "aws_key_name" {
    description = "Name of the SSH keypair to use in AWS."
}
variable "access_key" {}
variable "secret_key" {}
variable "aws_region" {
    default = "us-west-2"
}
variable "aws_vpc_cidr_block" {
    default = "10.11.0.0/16"
}

variable "aws_subnet_cidr_block" {
    default = "10.11.12.0/24"
}

variable "aws_ips" {
    default = {
        "0" = "10.11.12.100"
        "1" = "10.11.12.101"
        "2" = "10.11.12.102"
    }
}

# CoreOS Alpha Channel
variable "aws_amis" {
    default = {
        "us-west-2" = "ami-8bdeffbb"
    }
}

provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.aws_region}"
}

resource "aws_internet_gateway" "coreos" {
    vpc_id = "${aws_vpc.coreos.id}"

    tags {
        Name = "coreos"
    }
}

resource "aws_main_route_table_association" "coreos" {
    vpc_id = "${aws_vpc.coreos.id}"
    route_table_id = "${aws_route_table.coreos.id}"
}

resource "aws_route_table" "coreos" {
    vpc_id = "${aws_vpc.coreos.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.coreos.id}"
    }

    tags {
        Name = "coreos"
    }
}

resource "aws_route_table_association" "coreos" {
    subnet_id = "${aws_subnet.coreos.id}"
    route_table_id = "${aws_route_table.coreos.id}"
}

resource "aws_vpc" "coreos" {
    cidr_block = "${var.aws_vpc_cidr_block}"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags {
        Name = "coreos"
    }
}

resource "aws_subnet" "coreos" {
    vpc_id = "${aws_vpc.coreos.id}"
    cidr_block = "${var.aws_subnet_cidr_block}"
    map_public_ip_on_launch = true

    tags {
        Name = "coreos"
    }
}


resource "aws_security_group" "coreos" {
    name = "coreos"
    description = "Allow all inbound between nodes"
    vpc_id = "${aws_vpc.coreos.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.coreos.cidr_block}"]
    }

    ingress {
        from_port = 2379
        to_port = 2379
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.coreos.cidr_block}"]
    }

    ingress {
        from_port = 2380
        to_port = 2380
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.coreos.cidr_block}"]
    }
}

resource "aws_instance" "coreos_host" {
    instance_type = "t1.micro"
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    subnet_id = "${aws_subnet.coreos.id}"
    count = 3
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.coreos.id}"]
    private_ip = "${lookup(var.aws_ips, count.index)}"
    user_data = "${file("user-data")}"
    tags {
        Name = "coreos-${count.index}"
    }

    depends_on = ["aws_internet_gateway.coreos"]
}

output "addresses" {
  value = "${join(",",aws_instance.coreos_host.*.public_dns)}"
}
