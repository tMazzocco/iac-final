# AWS auth for Terraform

Terraform needs an IAM user with an access key.
Permissions below are the minimum to build: VPC + subnets + internet gateway +
route tables + security groups, 4 EC2 instances, 1 bastion, 1 Load Balancer.

## 1. Create the user

IAM → **Users** → **Create user**

- name: `terraform-iac-final`
- console access: **unticked** (API only, no password)

## 2. Give it permissions

IAM → **Policies** → **Create policy** → **Visual** tab.
Three blocks (**Add more permissions** between each). Name it
`TerraformIacInfra`, then attach it to the user.

### Block 1 — service **EC2**

Resources **All**

Auth needed:

```
CreateVpc
DeleteVpc
ModifyVpcAttribute
DescribeVpcs
DescribeVpcAttribute
CreateSubnet
DeleteSubnet
ModifySubnetAttribute
DescribeSubnets
CreateInternetGateway
AttachInternetGateway
DetachInternetGateway
DeleteInternetGateway
DescribeInternetGateways
CreateRouteTable
DeleteRouteTable
AssociateRouteTable
DisassociateRouteTable
DescribeRouteTables
CreateRoute
DeleteRoute
CreateSecurityGroup
DeleteSecurityGroup
AuthorizeSecurityGroupIngress
AuthorizeSecurityGroupEgress
RevokeSecurityGroupIngress
RevokeSecurityGroupEgress
DescribeSecurityGroups
DescribeSecurityGroupRules
RunInstances
TerminateInstances
DescribeInstances
DescribeInstanceAttribute
DescribeInstanceTypes
DescribeInstanceCreditSpecifications
DescribeInstanceStatus
ImportKeyPair
DeleteKeyPair
DescribeKeyPairs
CreateTags
DeleteTags
DescribeTags
AllocateAddress
ReleaseAddress
AssociateAddress
DisassociateAddress
DescribeAddresses
DescribeVolumes
DescribeNetworkInterfaces
DescribeImages
DescribeAvailabilityZones
```

### Block 2 — service **Elastic Load Balancing V2**

Resources **All**.

```
CreateLoadBalancer
DeleteLoadBalancer
ModifyLoadBalancerAttributes
DescribeLoadBalancers
DescribeLoadBalancerAttributes
CreateTargetGroup
DeleteTargetGroup
ModifyTargetGroup
ModifyTargetGroupAttributes
DescribeTargetGroups
DescribeTargetGroupAttributes
CreateListener
DeleteListener
ModifyListener
DescribeListeners
RegisterTargets
DeregisterTargets
DescribeTargetHealth
SetSecurityGroups
SetSubnets
AddTags
RemoveTags
DescribeTags
```

### Block 3 — service **STS**

Resources **All**

```
GetCallerIdentity
```


## 3. Access key — CLI only

User `terraform-iac` → **Security credentials** → **Create access key**.

- use case: **Command Line Interface (CLI)**
- tick the acknowledgement → **Next** → **Create access key**
- copy the secret or download the .csv now, it is shown once

Secret goes in `~/.aws/credentials` only. Never in the repo, a `.tf` file, or
`docker-compose.yml`.

## 4. Use it

Nothing to install on the host: the container already ships aws-cli, and it can
write the config itself. The `~/.aws` mount just has to be writable for that one
command.

1. In `docker-compose.yml`, comment out `read_only: true` under the `~/.aws`
   mount.
2. Create the folder and start the container:

```powershell
mkdir $HOME\.aws -Force
```

```powershell
docker compose up -d
```

3. Configure from inside — key id, secret, region `us-east-1`, output `json`:

```powershell
docker compose exec iac aws configure
```

4. Put `read_only: true` back, then recreate so the container can no longer
   write your credentials:

```powershell
docker compose up -d --force-recreate
```

5. Check:

```powershell
docker compose exec iac aws sts get-caller-identity
```

Expected: ARN ending in `user/terraform-iac`.

This writes the `default` profile. For a named profile instead, use
`aws configure --profile iac` and add `AWS_PROFILE=iac` to a `.env` file in the
project root.

The credentials live on the host in `~/.aws`, outside the repo. Never put them
in a `.tf` file or in `docker-compose.yml`.
