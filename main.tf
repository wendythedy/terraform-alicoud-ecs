# 
# Create a new VPC group, vSwitch, and Security Group
#
# Author: Wendy Thedy
# Creation Date: 24-06-2020
# Last Update: 24-06-2020

# Get a list of availability zones
data "alicloud_zones" "abc_zones" {}

# Get a list of cheap instance types we can use for our demo
data "alicloud_instance_types" "mem4g" {
  memory_size       = 4
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Set up provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
  version    = "~> 1.58"
}

# Create a new VPC group
resource "alicloud_vpc" "demo-vpc" {
  name       = "tf-demo-vpc"
  cidr_block = "${var.vpc_cidr_block}"
}

# Create a new vswitch
resource "alicloud_vswitch" "demo-vswitch" {
  name              = "tf-demo-vswitch"
  vpc_id            = "${alicloud_vpc.demo-vpc.id}"
  cidr_block        = "${var.vswitch_cidr_block}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Set up Security Group and associated rules
resource "alicloud_security_group" "demo-sg" {
  name        = "tf-demo-sg"
  description = "Security group for development subnet"
  vpc_id      = "${alicloud_vpc.demo-vpc.id}"
}

resource "alicloud_security_group_rule" "inbound-ping" {
  type              = "ingress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.demo-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound-iperf" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "5001/5001"
  security_group_id = "${alicloud_security_group.demo-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound-ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.demo-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

# SSH key pair for instance login
resource "alicloud_key_pair" "demo-key" {
  key_name = "${var.ssh_key_name}"
  key_file = "${var.ssh_key_name}.pem"
}

# Create a new ECS instance
resource "alicloud_instance" "demo-ecs" {
  instance_name = "tf-demo-ecs"
  host_name     = "demo"

  image_id = "${var.os_type}"

  instance_type        = "${data.alicloud_instance_types.mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.demo-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.demo-vswitch.id}"

  # Script to install tools
  user_data = "${file("install.sh")}"

  # SSH key for instance login
  key_name = "${alicloud_key_pair.demo-key.key_name}"

  # Make sure a public IP is assigned, with maximum bandwidth
  internet_max_bandwidth_out = 100
}
