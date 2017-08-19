# Simple Docker, Terraform and AWS deployment

## Introduction

Basic Node.js application was taken as an example and deployed to AWS using Terraform. The node.js application is deployed in a scalable way.

Because it's simple installation we don't take such concepts as AWS Elastic Load Balance. Even docker-compose is not the right tool for production and HA systems. But it's simple and does really cool things. We will see its strengths and weakness.

Load balancing Node.js application will be done using Nginx.

## Node.js

We use simple Node.js applications https://www.tutorialspoint.com/nodejs/nodejs_first_application.htm

We use official node container as our primary container with Alpine Linux (small, simple and secured). Few extra lines added to copy our Node.js files into the container and start it. We expose only 8801 port.

## Nginx

Nginx container also inherited from official Nginx container. We rewrite standard nginx config with our custom configuration. We don't use virtual hosts and our server list is hard coded.

## Docker Compose

Docker compose configuration file docker-compose.yml contains two containers. One is Node.js container and another is Nginx container. Nginx container has the link to the Node.js container, this will give network access to web container and also injects hosts names.

We scale web container to two. Nginx configuration has predefined two host names. Unfortunately to create elastic scale application you need to create complex project structure. Dynamically update web app list and restart Nginx server.

docker-compose up -d --scale web=2

## AWS Deployment

Create AWS key pairs. We will use it to ssh to aws instance. All other stuff will be created by Terraform.

Get public key
ssh-keygen -y -f KEYPAIR.pem

Export environment variables.

$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"
$ export AWS_DEFAULT_REGION="us-east-1"

## Terraform

The script will create all necessary part of AWS infrastructure VPC, subnet, and security group. We are using only one small t2.micro. Even if our application has two Node.js application the stack doesn't have HA. Becuase if we lose instance, we will lose our website.

SecurityGroup allows only SSH and HTTP ports. This means that only Nginx container will be reachable from the public network.

$ terraform plan
$ terraform apply
