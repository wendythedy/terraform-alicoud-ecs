# 
# Create a new VPC group, vSwitch, and Security Group
#
# Author: Wendy Thedy
# Creation Date: 24-06-2020
# Last Update: 09-07-2020

# Get a list of availability zones
data "alicloud_zones" "abc_zones" {}

# Get a list of cheap instance types we can use for our demo 
data "alicloud_instance_types" "mem05g" {
  memory_size       = 0.5
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Set up provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
}

# Create a new VPC group
resource "alicloud_vpc" "tf-demo-vpc" {
  name       = "tf-demo-vpc"
  cidr_block = "${var.vpc_cidr_block}"
}

# Create a new vswitch
resource "alicloud_vswitch" "tf-demo-vswitch-public-A" {
  name              = "tf-demo-vswitch-public-A"
  vpc_id            = "${alicloud_vpc.tf-demo-vpc.id}"
  cidr_block        = "${var.vswitch_cidr_block_public_A}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

resource "alicloud_vswitch" "tf-demo-vswitch-public-B" {
  name              = "tf-demo-vswitch-public-B"
  vpc_id            = "${alicloud_vpc.tf-demo-vpc.id}"
  cidr_block        = "${var.vswitch_cidr_block_public_B}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.1.id}"
}

resource "alicloud_vswitch" "tf-demo-vswitch-private-A" {
  name              = "tf-demo-vswitch-private-A"
  vpc_id            = "${alicloud_vpc.tf-demo-vpc.id}"
  cidr_block        = "${var.vswitch_cidr_block_private_A}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

resource "alicloud_vswitch" "tf-demo-vswitch-private-B" {
  name              = "tf-demo-vswitch-private-B"
  vpc_id            = "${alicloud_vpc.tf-demo-vpc.id}"
  cidr_block        = "${var.vswitch_cidr_block_private_B}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.1.id}"
}

# Set up Security Group and associated rules
resource "alicloud_security_group" "tf-demo-sg-public" {
  name        = "tf-demo-sg-public"
  description = "Security group for development subnet"
  vpc_id      = "${alicloud_vpc.tf-demo-vpc.id}"
}

resource "alicloud_security_group" "tf-demo-sg-private" {
  name        = "tf-demo-sg-private"
  description = "Security group for development subnet"
  vpc_id      = "${alicloud_vpc.tf-demo-vpc.id}"
}

# Set up Security Rule for Public Security Group
resource "alicloud_security_group_rule" "inbound-ping-frontend" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.tf-demo-sg-public.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound-iperf-frontend" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "5001/5001"
  security_group_id = "${alicloud_security_group.tf-demo-sg-public.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound-ssh-frontend" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.tf-demo-sg-public.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound-http-frontend" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  security_group_id = "${alicloud_security_group.tf-demo-sg-public.id}"
  cidr_ip           = "0.0.0.0/0"
}

# Set up Security Rule for Private Security Group
resource "alicloud_security_group_rule" "inbound-ping-backend" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.tf-demo-sg-private.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound-iperf-backend" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "5001/5001"
  security_group_id = "${alicloud_security_group.tf-demo-sg-private.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound-ssh-backend" {
  type                      = "ingress"
  ip_protocol               = "tcp"
  policy                    = "accept"
  port_range                = "22/22"
  security_group_id         = "${alicloud_security_group.tf-demo-sg-private.id}"
  source_security_group_id  = "${alicloud_security_group.tf-demo-sg-public.id}"
}

resource "alicloud_security_group_rule" "inbound-http-backend" {
  type                      = "ingress"
  ip_protocol               = "tcp"
  policy                    = "accept"
  port_range                = "80/80"
  security_group_id         = "${alicloud_security_group.tf-demo-sg-private.id}"
  source_security_group_id  = "${alicloud_security_group.tf-demo-sg-public.id}"
}

# SSH key pair for instance login
resource "alicloud_key_pair" "tf-demo-key" {
  key_name = "${var.ssh_key_name}"
  key_file = "${var.ssh_key_name}.pem"
}

# Create a new Frontend ECS instance in Zone A
resource "alicloud_instance" "tf-demo-frontend-ecs-A" {
  instance_name = "tf-demo-frontend-ecs-A"
  host_name     = "frontend"

  image_id = "${var.os_type}"

  instance_type        = "${data.alicloud_instance_types.mem05g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  system_disk_size     = "20"
  security_groups      = ["${alicloud_security_group.tf-demo-sg-public.id}"]
  vswitch_id           = "${alicloud_vswitch.tf-demo-vswitch-public-A.id}"

  # Script to install tools
  user_data = "${file("install.sh")}"

  # SSH key for instance login
  key_name = "${alicloud_key_pair.tf-demo-key.key_name}"

  # Make sure a public IP is assigned, with maximum bandwidth
  internet_max_bandwidth_out = 100
}

# Create a new Frontend ECS instance in Zone B
resource "alicloud_instance" "tf-demo-frontend-ecs-B" {
  instance_name = "tf-demo-frontend-ecs-B"
  host_name     = "frontend"

  image_id = "${var.os_type}"

  instance_type        = "${data.alicloud_instance_types.mem05g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  system_disk_size     = "20"
  security_groups      = ["${alicloud_security_group.tf-demo-sg-public.id}"]
  vswitch_id           = "${alicloud_vswitch.tf-demo-vswitch-public-B.id}"

  # Script to install tools
  user_data = "${file("install.sh")}"

  # SSH key for instance login
  key_name = "${alicloud_key_pair.tf-demo-key.key_name}"

  # Make sure a public IP is assigned, with maximum bandwidth
  internet_max_bandwidth_out = 100
}

# Create a new Backend ECS instance in Zone A
resource "alicloud_instance" "tf-demo-backend-ecs-A" {
  instance_name = "tf-demo-backend-ecs-A"
  host_name     = "backend"

  image_id = "${var.os_type}"

  instance_type        = "${data.alicloud_instance_types.mem05g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  system_disk_size     = "20"
  security_groups      = ["${alicloud_security_group.tf-demo-sg-private.id}"]
  vswitch_id           = "${alicloud_vswitch.tf-demo-vswitch-private-A.id}"

  # Script to install tools
  user_data = "${file("install.sh")}"

  # SSH key for instance login
  key_name = "${alicloud_key_pair.tf-demo-key.key_name}"

  # Make sure a public IP is assigned, with maximum bandwidth
  internet_max_bandwidth_out = 0
}

# Create a new Backend ECS instance in Zone B
resource "alicloud_instance" "tf-demo-backend-ecs-B" {
  instance_name = "tf-demo-backend-ecs-B"
  host_name     = "backend"

  image_id = "${var.os_type}"

  instance_type        = "${data.alicloud_instance_types.mem05g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  system_disk_size     = "20"
  security_groups      = ["${alicloud_security_group.tf-demo-sg-private.id}"]
  vswitch_id           = "${alicloud_vswitch.tf-demo-vswitch-private-B.id}"

  # Script to install tools
  user_data = "${file("install.sh")}"

  # SSH key for instance login
  key_name = "${alicloud_key_pair.tf-demo-key.key_name}"

  # Make sure a public IP is assigned, with maximum bandwidth
  internet_max_bandwidth_out = 0
}

# Create Server Load Balancer for Frontend
resource "alicloud_slb" "tf-demo-slb-frontend" {
  name       = "tf-demo-slb-frontend"
  vswitch_id = "${alicloud_vswitch.tf-demo-vswitch-public-A.id}"
}

resource "alicloud_slb_listener" "tf-demo-slb-lst-frontend" {
  load_balancer_id          = "${alicloud_slb.tf-demo-slb-frontend.id}"
  backend_port              = 80
  frontend_port             = 80
  protocol                  = "http"
  bandwidth                 = 5
  health_check_connect_port = 80
}

resource "alicloud_slb_backend_server" "tf-demo-slb-bs-frontend" {
    load_balancer_id = "${alicloud_slb.tf-demo-slb-frontend.id}"

    backend_servers {
      server_id = "${alicloud_instance.tf-demo-frontend-ecs-A.id}"
      weight     = 100
    }

    backend_servers {
      server_id = "${alicloud_instance.tf-demo-frontend-ecs-B.id}"
      weight     = 100
    }
}

# Create Server Load Balancer for Backend
resource "alicloud_slb" "tf-demo-slb-backend" {
  name       = "tf-demo-slb-backend"
  vswitch_id = "${alicloud_vswitch.tf-demo-vswitch-private-A.id}"
}

resource "alicloud_slb_listener" "tf-demo-slb-lst-backend" {
  load_balancer_id          = "${alicloud_slb.tf-demo-slb-backend.id}"
  backend_port              = 80
  frontend_port             = 80
  protocol                  = "http"
  bandwidth                 = 5
  health_check_connect_port = 80
}

resource "alicloud_slb_backend_server" "tf-demo-slb-bs-backend" {
    load_balancer_id = "${alicloud_slb.tf-demo-slb-backend.id}"

    backend_servers {
      server_id = "${alicloud_instance.tf-demo-backend-ecs-A.id}"
      weight     = 100
    }

    backend_servers {
      server_id = "${alicloud_instance.tf-demo-backend-ecs-B.id}"
      weight     = 100
    }
}

# Create a new EIP for Frontend SLB
resource "alicloud_eip" "tf-demo-eip-frontend-slb" {
  bandwidth            = "1"
  internet_charge_type = "PayByBandwidth"
}

#Assosiate EIP with Frontend SLB
resource "alicloud_eip_association" "tf-demo-eip-asso-frontend-slb" {
  allocation_id = "${alicloud_eip.tf-demo-eip-frontend-slb.id}"
  instance_id   = "${alicloud_slb.tf-demo-slb-frontend.id}"
}
