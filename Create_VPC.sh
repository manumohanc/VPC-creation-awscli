#!/bin/bash
#Script assumes that AWS CLI was configured, output format is set to JSON and jq package is installed
#Varibles
vpc_name="Blackbox-VPC"
vpc_block="192.168.1.0/24"
pubsubnet_name="Blackbox-Public-Subnet"
prisubnet_name="Blackbox-Private-Subnet"
azone="ap-south-1a"
pub_rtable_name="Public-Blackbox-RouteTable"
pri_rtable_name="Private-Blackbox-RouteTable"
sn_block1="192.168.1.0/26"
sn_block2="192.168.1.64/26"
sn_block3="192.168.1.128/26"
sn_block4="192.168.1.192/26"
gw_name="Blackbox-Gateway"
rt_name="Blackbox-RT"
dest_cidr="0.0.0.0/0"
sg_name="Blackbox-SecurityGroup"
sg_cidr="0.0.0.0/0"
key_name="Blackbox-key"
inst_name="Blackbox-Instance"
nat_gw="Blackbox-NAT-Gateway"
 
#Prereq
rm -rf Blackbox-key.pem /tmp/output.txt
 
#Main
echo " Creating VPC............"
sleep 1
aws ec2 create-vpc --cidr-block 192.168.1.0/24 > /tmp/output.txt
vpc_id=$(cat /tmp/output.txt|/usr/bin/jq '.Vpc.VpcId' | sed 's/\"//g')
aws ec2 create-tags --resources "$vpc_id" --tags Key=Name,Value="$vpc_name"
echo " VPC: $vpc_name Created with block $vpc_block"
echo " Enabling DNS Hostnames"
aws ec2 modify-vpc-attribute --vpc-id "$vpc_id" --enable-dns-hostnames "{\"Value\":true}"  &>/dev/null
 
echo " Creating Internet Gateway................"
aws ec2 create-internet-gateway > /tmp/output.txt
ig_id=$(cat /tmp/output.txt|  /usr/bin/jq '.InternetGateway.InternetGatewayId' | sed 's/\"//g')
aws ec2 create-tags --resources "$ig_id" --tags Key=Name,Value="$gw_name"
aws ec2 attach-internet-gateway --internet-gateway-id "$ig_id" --vpc-id "$vpc_id"
echo " Internet Gateway: $ig_id Created and attached to VPC: $vpc_name "
 
echo " Creating Public Subnet..........."
aws ec2 create-subnet --cidr-block "$sn_block1"  --availability-zone "$azone"  --vpc-id "$vpc_id" > /tmp/output.txt
s1_id=$(cat /tmp/output.txt|/usr/bin/jq '.Subnet.SubnetId' |sed 's/\"//g')
aws ec2 create-tags --resources "$s1_id" --tags Key=Name,Value="$pubsubnet_name" &>/dev/null
echo " Subnet: $pubsubnet_name Created with VPC $vpc_name "
echo " Enabling public IP in subnet"
aws ec2 modify-subnet-attribute  --subnet-id "$s1_id"  --map-public-ip-on-launch &>/dev/null
 
echo " Creating Public Subnet..........."
aws ec2 create-subnet --cidr-block "$sn_block2"  --availability-zone "$azone"  --vpc-id "$vpc_id" > /tmp/output.txt
s2_id=$(cat /tmp/output.txt|/usr/bin/jq '.Subnet.SubnetId' |sed 's/\"//g')
aws ec2 create-tags --resources "$s2_id" --tags Key=Name,Value="$pubsubnet_name" &>/dev/null
echo " Subnet: $pubsubnet_name Created with VPC $vpc_name "
echo " Enabling public IP in subnet"
aws ec2 modify-subnet-attribute  --subnet-id "$s2_id"  --map-public-ip-on-launch &>/dev/null
 
echo " Creating Private Subnet..........."
aws ec2 create-subnet --cidr-block "$sn_block3"  --availability-zone "$azone"  --vpc-id "$vpc_id" > /tmp/output.txt
s3_id=$(cat /tmp/output.txt|/usr/bin/jq '.Subnet.SubnetId' |sed 's/\"//g')
aws ec2 create-tags --resources "$s3_id" --tags Key=Name,Value="$prisubnet_name" &>/dev/null
echo " Subnet: $prisubnet_name Created with VPC $vpc_name "
 
echo " Creating Private Subnet..........."
aws ec2 create-subnet --cidr-block "$sn_block4"  --availability-zone "$azone"  --vpc-id "$vpc_id" > /tmp/output.txt
s4_id=$(cat /tmp/output.txt|/usr/bin/jq '.Subnet.SubnetId' |sed 's/\"//g')
aws ec2 create-tags --resources "$s4_id" --tags Key=Name,Value="$prisubnet_name" &>/dev/null
echo " Subnet: $prisubnet_name Created with VPC $vpc_name "
 
echo " Allocating IP address for NAT Gateway"
aws ec2 allocate-address --domain vpc > /tmp/output.txt
alloc_id=$(cat /tmp/output.txt|  /usr/bin/jq '.AllocationId'|sed 's/\"//g')
echo "Creating NAT GATEWAY..........."
aws ec2 create-nat-gateway --subnet-id "$s1_id" --allocation-id "$alloc_id" > /tmp/output.txt
gw_id=$(cat /tmp/output.txt|  /usr/bin/jq '.NatGateway.NatGatewayId'| sed 's/\"//g')
aws ec2 create-tags --resources "$gw_id" --tags Key=Name,Value="$nat_gw" &>/dev/null
 
echo " Creating Public route table.........."
aws ec2 create-route-table --vpc-id "$vpc_id" > /tmp/output.txt
rt_id=$(cat /tmp/output.txt | /usr/bin/jq '.RouteTable.RouteTableId' | sed 's/\"//g')
aws ec2 create-tags --resources "$rt_id" --tags Key=Name,Value="$pub_rtable_name"
echo " Creating routes to InternetGateway"
aws ec2 create-route --route-table-id "$rt_id" --destination-cidr-block 0.0.0.0/0 --gateway-id "$ig_id" &>/dev/null
echo " Associating Route table to subnets......."
aws ec2 associate-route-table --route-table-id "$rt_id" --subnet-id "$s1_id" &>/dev/null
aws ec2 associate-route-table --route-table-id "$rt_id" --subnet-id "$s2_id" &>/dev/null
 
 
echo " Creating Private route table.........."
aws ec2 create-route-table --vpc-id "$vpc_id" > /tmp/output.txt
rt_id=$(cat /tmp/output.txt | /usr/bin/jq '.RouteTable.RouteTableId' | sed 's/\"//g')
aws ec2 create-tags --resources "$rt_id" --tags Key=Name,Value="$pri_rtable_name"
echo " Creating routes to NAT Gateway"
aws ec2 create-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id "$gw_id" &>/dev/null
aws ec2 associate-route-table --route-table-id "$rt_id" --subnet-id "$s3_id" &>/dev/null
aws ec2 associate-route-table --route-table-id "$rt_id" --subnet-id "$s4_id" &>/dev/null
 
 
echo " Creating Security Group............."
aws ec2 create-security-group  --group-name "$sg_name"  --description "Private: $sg_name"  --vpc-id "$vpc_id" > /tmp/output.txt
sg_id=$(cat /tmp/output.txt|  /usr/bin/jq '.GroupId'| sed 's/\"//g')
aws ec2 create-tags --resources "$sg_id" --tags Key=Name,Value="$sg_name"
echo " Enabling access via port 22, 80 and 443 in Security Group"
aws ec2 authorize-security-group-ingress --group-id "$sg_id"  --protocol tcp --port 22  --cidr "$sg_cidr" &>/dev/null
aws ec2 authorize-security-group-ingress --group-id "$sg_id"  --protocol tcp --port 80  --cidr "$sg_cidr" &>/dev/null
aws ec2 authorize-security-group-ingress --group-id "$sg_id"  --protocol tcp --port 443  --cidr "$sg_cidr" &>/dev/null
 
echo " Creating Key/Pair..............."
aws ec2 create-key-pair --key-name "$key_name" --query 'KeyMaterial' --output text > "$key_name".pem
chmod 400 "$key_name".pem
 
echo " Launching Instance in Public Subnet..............."
aws ec2 run-instances --image-id ami-074dc0a6f6c764218 --instance-type t2.micro --count 1 --subnet-id "$s1_id" --security-group-ids "$sg_id" --associate-public-ip-address --key-name "$key_name" > /tmp/output.txt
inst_id=$(cat /tmp/output.txt| /usr/bin/jq '.Instances[0].InstanceId'| sed 's/\"//g')
aws ec2 create-tags --resources "$inst_id" --tags Key=Name,Value="$inst_name" &>/dev/null
sleep 4
echo " Instance Created with ID: $inst_id"
 
echo " Launching Instance in Private Subnet..............."
aws ec2 run-instances --image-id ami-074dc0a6f6c764218 --instance-type t2.micro --count 1 --subnet-id "$s3_id" --security-group-ids "$sg_id" --key-name "$key_name" > /tmp/output.txt
inst_id=$(cat /tmp/output.txt| /usr/bin/jq '.Instances[0].InstanceId'| sed 's/\"//g')
aws ec2 create-tags --resources "$inst_id" --tags Key=Name,Value="$inst_name" &>/dev/null
sleep 4
echo " Instance Created with ID: $inst_id"
