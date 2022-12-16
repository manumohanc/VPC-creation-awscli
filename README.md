# VPC-creation-awscli
## Create an entire VPC with help of AWSCLI
I was fairly adamant that I would never use a terminal or a Command prompt before I started learning Linux. I thought it was more difficult than working on a nice GUI and clicking a few buttons, also because it was visually unattractive and, more significantly, challenging. After using Linux for a few years, I was humbled into believing that the terminal is the only easier and cleaner option. The keyboard had turned mightier than the mouse. Fast-forward a few years, the person I had become began to find the GUI of AWS Infrastructure Management challenging. At some point, I discovered the AWS CLI tools and began investigating different ways to control the AWS infrastructure without ever leaving my terminal. Here is what I learned. 

## Table of Contents
1. [Prerequisites](#Prerequisites)
2. [Create a VPC](#Create-a-VPC)
3. [Create Internet gateway](#Create-Internet-gateway)
4. [Create Public Subnet](#Create-Public-Subnet)
5. [Creating NAT Gateway](#Creating-NAT-Gateway)
6. [Create Private Subnet](#Create-Private-Subnet)
7. [Create Security Group to enable access via ports 22, 80 and 443](#Create-Security-Group-to-enable-access-via-ports-22,-80-and-443)
8. [Create Key Pair](#Create-Key-Pair)
9. [Create Instance in public subnet](#Create-Instance-in-public-subnet)
10. [Create Instance in private subnet](#Create-Instance-in-private-subnet)

## Prerequisites
 - Create AWS account 

 - Setup AWS CLI
   Use the following commands to load the binary in a Linux distro
    ```sh
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --bin-dir /usr/local/bin
    ```
   Amazon documentation can be found [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
   
 - Configure AWS CLI
    Create a user with programmatic access and take note of the access key and secret key.
    Next run aws configure command which will prompt for additional details and save it as a profile named default.
     ```sh
     $ aws configure
     AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
     AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
     Default region name [None]: us-west-2
     Default output format [None]: json
     ```
    Amazon documentation can be found [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
    
 - Install jq Command-line JSON processor.
    jq also known as JSON Processor an open-source tool available on Linux Based Systems to process the JSON output and query the desired results.
     ```sh
     yum install epel-release -y
     yum install jq -y
     jq -Version
     ```

## Create a VPC
 With the help of Amazon Virtual Private Cloud (Amazon VPC), you may start launching AWS resources into a defined virtual network. This virtual network has the advantage of using the scalable infrastructure of AWS while closely resembling a conventional network that you would operate in your own data center. 
 
 Create the VPC using the preferred CIDR block.
  ```sh
  aws ec2 create-vpc --cidr-block <CIDR_BLOCK>
  ```
 Tag the newly created VPC
  ```sh
  aws ec2 create-tags --resources "<vpc_id>" --tags Key=Name,Value="<vpc_name>"
  ```
 Enable DNS hostname resolution
  ```sh
  aws ec2 modify-vpc-attribute --vpc-id "<vpc_id>" --enable-dns-hostnames "{\"Value\":true}"
  ```

## Create an Internet Gateway
 An internet gateway is a horizontally scaled, redundant, and highly available VPC component that allows communication between your VPC and the internet. It supports    IPv4 and IPv6 traffic. An internet gateway enables resources in your public subnets (such as EC2 instances) to connect to the internet if the resource has a public IPv4 address or an IPv6 address. Similarly, resources on the internet can initiate a connection to resources in your subnet using the public IPv4 address or IPv6 address.

 Create Internet Gateway 
 ```sh
 aws ec2 create-internet-gateway
 aws ec2 create-tags --resources "<internetgateway_id>" --tags Key=Name,Value=<internetgateway_name>
 ```
 Attach Internet Gateway to VPC
 ```sh
 aws ec2 attach-internet-gateway --internet-gateway-id "<internetgateway_id>" --vpc-id "<vpc_id>"
 ```

## Create a Public Subnet
 A public subnet is a subnet that is associated with a route table that has a route to an Internet gateway. This connects the VPC to the Internet and to other AWS services.
 
 Create a Public Subnet
 ```sh
 aws ec2 create-subnet --cidr-block "<CIDR_BLOCK>"  --availability-zone "<azone>"  --vpc-id "<vpc_id>"
 aws ec2 create-tags --resources "<Subnet_id>" --tags Key=Name,Value="<Subnet_Name>"
 aws ec2 modify-subnet-attribute  --subnet-id "<Subnet_id>"  --map-public-ip-on-launch
 ```
 
 Create Public Route Table
 ```sh
 aws ec2 create-route-table --vpc-id "<vpc_id>"
 aws ec2 create-tags --resources "<routetable_id>" --tags Key=Name,Value="<routetable_name>"
 ```
 
 Create a route to Internet gateway for Public Route table and associate to subnets
 ```sh
 aws ec2 create-route --route-table-id "<routetable_id>" --destination-cidr-block 0.0.0.0/0 --gateway-id "<gateway_id>"
 aws ec2 associate-route-table --route-table-id "<routetable_id>" --subnet-id "<Subnet_id>"
 ```
 
## Creating NAT Gateway
 NAT Gateway is a highly available AWS managed service that makes it easy to connect to the Internet from instances within a private subnet in an Amazon Virtual Private Cloud (Amazon VPC).
 
 Allocate IP address for the NAT Gateway.
 ```sh 
 aws ec2 allocate-address --domain vpc
 ```
 Create the NAT Gateway with the Elastic IP address.
 ```sh
 aws ec2 create-nat-gateway --subnet-id "<Subnet_id>" --allocation-id "<Allocation_ID>"
 aws ec2 create-tags --resources "<gateway_id>" --tags Key=Name,Value="<Natgw_Name>" 
 ```

## Create a Private Subnet
A private subnet is a subnet that is associated with a route table that doesn’t have a route to an internet gateway. Instances in the private subnet are usually backend servers that doesn't require traffic from the internet. Private subnet's route table has a route specified to connect to the NAT gateway.

 Create the Private Subnet
 ```sh
 aws ec2 create-subnet --cidr-block "<CIDR_BLOCK>"  --availability-zone "<azone>"  --vpc-id "<vpc_id>"
 aws ec2 create-tags --resources "<Subnet_id>" --tags Key=Name,Value="<Subnet_Name>"
 ```
 
 Create a private route table
 ```sh
 aws ec2 create-route-table --vpc-id "<vpc_id>" 
 aws ec2 create-tags --resources "<routetable_id>" --tags Key=Name,Value="<routetable_name>"
 ```

 Create routes to NAT Gateway and associate route table to Private subnet
 ```sh
 aws ec2 create-route --route-table-id <routetable_id> --destination-cidr-block 0.0.0.0/0 --gateway-id "<gateway_id>" 
 aws ec2 associate-route-table --route-table-id "<routetable_id>" --subnet-id "<Subnet_id>" 
 ```

## Create a Security Group to enable access via ports 22, 80 and 443
 A security group acts as a virtual firewall for your EC2 instances to control incoming and outgoing traffic. Inbound rules control the incoming traffic to your instance, and outbound rules control the outgoing traffic from your instance. In this case, we will be allowing access to ports 22, 80 and 443 via security groups.

 Create Security Group
 ```sh
 aws ec2 create-security-group  --group-name "<securitygroup_name>"  --description "<description>"  --vpc-id "$vpc_id"
 aws ec2 create-tags --resources "<securitygroup_id>" --tags Key=Name,Value="<securitygroup_name>"
 aws ec2 authorize-security-group-ingress --group-id "<securitygroup_id>"  --protocol tcp --port 22  --cidr 
 aws ec2 authorize-security-group-ingress --group-id "<securitygroup_id>"  --protocol tcp --port 80  --cidr 
 aws ec2 authorize-security-group-ingress --group-id "<securitygroup_id>"  --protocol tcp --port 443  --cidr 
 ```

## Create Key Pair
 A key pair, consisting of a public key and a private key, is a set of security credentials that you use to prove your identity when connecting to an Amazon EC2 instance. Amazon EC2 stores the public key on your instance, and you store the private key. For Linux instances, the private key allows you to securely SSH into your instance. 
 
 Create Key Pair
 ```sh
 aws ec2 create-key-pair --key-name "<key_name>" --query 'KeyMaterial' --output text
 ```

## Create an Instance in the public subnet
 Now let us create an instance in public subnet. We must ensure that a pulic IP adress is assosiated at the creation of the instance. 
 ```sh
 aws ec2 run-instances --image-id ami-074dc0a6f6c764218 --instance-type t2.micro --count 1 --subnet-id "<Subnet_id>" --security-group-ids "<securitygroup_id>" --associate-public-ip-address --key-name "<key_name>"
 aws ec2 create-tags --resources "<Instance_id>" --tags Key=Name,Value="<Instance_name>" &>/dev/null
 ```

## Create an Instance in the private subnet
 Lets create an instance in private subnet. 
 ```sh
 aws ec2 run-instances --image-id ami-074dc0a6f6c764218 --instance-type t2.micro --count 1 --subnet-id "<Subnet_id>" --security-group-ids "<securitygroup_id>" --key-name "<key_name>"
 aws ec2 create-tags --resources "<Instance_id>" --tags Key=Name,Value="<Instance_name>" &>/dev/null
 ```
