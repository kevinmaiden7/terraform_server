provider "aws" {
    region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
    name = "terraform-kevin-cluster"
    image_id = "ami-0e82959d4ed12de3f"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, Kevin" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF

    lifecycle{
        create_before_destroy = true
    }
}

data "aws_availability_zones" "all" {
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    availability_zones = data.aws_availability_zones.all.names
    load_balancers = [aws_elb.example.name]
    health_check_type = "ELB"

    min_size = 2
    max_size = 8

    tag {
        key = "Name"
        value = "terraform-kevin-asg-instance"
        propagate_at_launch = true
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-kevin-asg-secgroup"

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_elb" "example" {
    name = "terraform-kevin-elb"
    availability_zones = data.aws_availability_zones.all.names
    security_groups = [aws_security_group.elb.id]

    listener {
        lb_port = 80
        lb_protocol = "http"
        instance_port = 8080
        instance_protocol = "http"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3 # secs
        interval = 30 # secs
        target = "HTTP:8080/"
    }
}

resource "aws_security_group" "elb" {
    name = "terraform-kevin-elb-secgroup"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "elb_dns_name" {
    value = aws_elb.example.dns_name
}
