Terraform for Alibaba Cloud

This code contains a terraform script to build a simple infrastructure that has 2 backend servers and 2 frontend servers. To connect frontend server simply just call external SLB IP via port 80 then to connect to backend server need to connect through frontend server first to call external SLB IP via port 80. 

first rename and fill secret env (RAM) file terraform.tfvars.example to terraform.tfvars

use ./setup.sh to sun terraform apply

use./detroy.sh to run terraform destroy

