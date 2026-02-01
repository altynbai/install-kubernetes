# Kubernetes Cluster Bootstrap with Terraform

This directory contains Terraform code to automatically deploy a Kubernetes cluster on AWS EC2 instances.

## Architecture

- **1 Control Plane Node**: t3.xlarge (4GB RAM, 2 CPUs, 40GB disk)
- **3 Worker Nodes**: t3.2xlarge (8GB RAM, 4 CPUs, 40GB disk)

The cluster uses:
- Ubuntu 22.04 LTS
- Kubernetes v1.35.0
- Containerd as container runtime
- Cilium as the CNI plugin

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with your credentials
4. **EC2 Key Pair** created in your AWS region (see instructions below)

## AWS EC2 Key Pair Setup

Before deploying, create an EC2 key pair:

```bash
# Using AWS CLI
aws ec2 create-key-pair --key-name my-k8s-key --query 'KeyMaterial' --output text > ~/.ssh/my-k8s-key.pem
chmod 400 ~/.ssh/my-k8s-key.pem
```

Or create it through the AWS Console:
1. Go to EC2 Dashboard → Key Pairs
2. Click "Create key pair"
3. Name it (e.g., `my-k8s-key`)
4. Choose "RSA" and ".pem" format
5. Click "Create key pair" and save the `.pem` file

## Configuration

1. Copy the example configuration:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` and set:
   - `instance_key_pair`: The name of your EC2 key pair (e.g., `my-k8s-key`)
   - `aws_region`: Your desired AWS region (default: `us-east-1`)
   - `instance_ami`: Ubuntu 22.04 LTS AMI ID for your region
   - Other parameters as needed

3. Find the correct Ubuntu 22.04 LTS AMI ID for your region:
```bash
# Example for us-east-1
aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --region us-east-1
```

## Deployment

1. Initialize Terraform:
```bash
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

Terraform will output:
- Public and private IPs of all nodes
- SSH commands to connect to each node
- Kubernetes API endpoint

## Accessing the Cluster

### SSH into Control Plane

```bash
ssh -i ~/.ssh/my-k8s-key.pem ubuntu@<control_plane_public_ip>
```

### Get kubeconfig

Once connected to the control plane:

```bash
# Copy the kubeconfig to your local machine
scp -i ~/.ssh/my-k8s-key.pem ubuntu@<control_plane_public_ip>:/home/ubuntu/.kube/config ./kubeconfig
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes
```

### Monitor Cluster Setup

The Kubernetes installation happens during instance startup via user data scripts. To monitor progress:

```bash
# SSH into the control plane
ssh -i ~/.ssh/my-k8s-key.pem ubuntu@<control_plane_public_ip>

# Check the installation logs
tail -f /var/log/user-data.log

# Check if installation is complete
sudo kubectl get nodes
```

The worker nodes will wait for the control plane to be ready before joining the cluster.

## Verification

Once all instances are running:

```bash
# From the control plane
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
```

All nodes should show as "Ready".

## Cleanup

To destroy the cluster and all AWS resources:

```bash
terraform destroy
```

## Troubleshooting

### Connection Timeout
- Ensure your security group allows SSH (port 22) from your IP
- Check that the EC2 instances have public IP addresses assigned

### Installation Fails
- Check logs: `tail -f /var/log/user-data.log` on the instance
- Verify the Ubuntu 22.04 AMI is being used
- Check that the key pair exists in your AWS region

### Worker Nodes Not Joining
- Verify the control plane installation is complete: `sudo kubectl get nodes` on control plane
- Check worker logs: `tail -f /var/log/user-data.log` on worker instances
- Ensure security group allows communication between nodes (port 6443, 10250, etc.)

## Files

- `main.tf` - VPC, EC2 instances, security groups, and networking
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example configuration (copy to `terraform.tfvars`)
- `user_data_control_plane.sh` - Installation script for control plane
- `user_data_worker.sh` - Installation script for worker nodes
