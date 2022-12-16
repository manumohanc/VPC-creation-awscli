# VPC-creation-awscli
## Create entire VPC with help of AWSCLI
I was fairly adamant that I would never use a terminal or a Command prompt before I started learning Linux. I thought it was more difficult than working on a nice GUI and clicking a few buttons, also because it was visually unattractive and, more significantly, challenging. After using Linux for a few years, I was humbled into believing that the terminal is the only easier and cleaner option. The keyboard had overtaken the mouse in strength. The keyboard had turned mightier than the mouse. The person I had become began to find the GUI of AWS Infrastructure Management challenging. At some point, I discovered the AWS CLI tools and began investigating different ways to control the AWS infrastructure without ever leaving my terminal. Here is what i learned. 
## Table of contents
1. Prerequisites 
2. Create a VPC
3. Create public and private subnets
4. Create internet gateway for the VPC
5. Create an elastic IP address for NAT gateway
6. Create a NAT gateway
7. Create a route table for each subnet
8. Create routes
9. Associate route table to subnet
10. Create a security group for the VPC
11. Create Key-pair
12. Run an instance

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
    Create a user with programatic access and take a note of the access key and secret key
    Next run aws configure command which will prompt for addtional details and save it as a profile named default.
     ```sh
     $ aws configure
     AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
     AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
     Default region name [None]: us-west-2
     Default output format [None]: json
     ```
    Amazon documentation can be found [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
    
 - Install jq Command-line JSON processor
    jq also known as JSON Processor an open source tool available on Linux Based System to process the JSON output and query the desired results.
     ```sh
     yum install epel-release -y
     yum install jq -y
     jq -Version
     ```
