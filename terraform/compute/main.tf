provider "aws" {
  region = "us-east-1"
  profile = "mediawiki"
}

data "aws_availability_zones" "data_az" {
  
}

#-------------- Key-Pair --------------#
resource "aws_key_pair" "mw_key_pair" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "mw_instance_web_a" {
  ami = "${var.ami}"
  instance_type = "${var.web_instance_type}"
  key_name = "${aws_key_pair.mw_key_pair.id}"
  vpc_security_group_ids = ["${var.web_security_group}"]
  subnet_id = "${var.web_subnet_a}"

  tags{
    Name = "mw_instance_web_a"
    Project = "mediawiki"
  }
}

resource "aws_instance" "mw_instance_web_b" {
  ami = "${var.ami}"
  instance_type = "${var.web_instance_type}"
  key_name = "${aws_key_pair.mw_key_pair.id}"
  vpc_security_group_ids = ["${var.web_security_group}"]
  subnet_id = "${var.web_subnet_b}"

  tags{
    Name = "mw_instance_web_b"
    Project = "mediawiki"
  }
}

resource "aws_instance" "mw_instance_db" {
  ami = "${var.ami}"
  instance_type = "${var.web_instance_type}"
  key_name = "${aws_key_pair.mw_key_pair.id}"
  vpc_security_group_ids = ["${var.db_security_group}"]
  subnet_id = "${var.db_subnet}"

  tags{
    Name = "mw_instance_db"
    Project = "mediawiki"
  }
}

resource "aws_elb" "mw_elb" {
  name = "media_wiki_elb"
  subnets = ["${var.web_subnet_a}", "${var.web_subnet_b}"]
  instances = ["${aws_instance.mw_instance_web_a.id}", "${aws_instance.mw_instance_web_b}"]
  security_groups = ["${var.web_security_group}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "3"
    timeout             = "3"
    target              = "TCP:80"
    interval            = "30"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 300
  connection_draining         = true
  connection_draining_timeout = 300

  tags {
    Name = "mw_elb"
    Project = "mediawiki"
  }
}

  subnets = ["${aws_subnet.wp_public1_subnet.id}",
    "${aws_subnet.wp_public2_subnet.id}",
  ]

  security_groups = ["${aws_security_group.wp_public_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "${var.elb_healthy_threshold}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
    timeout             = "${var.elb_timeout}"
    target              = "TCP:80"
    interval            = "${var.elb_interval}"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "wp_${var.domain_name}-elb"
  }
}

