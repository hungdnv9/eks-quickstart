## Levelopment

### 1. Local development

```sh
$ git clone <>
$ python3 -m venv .venv
$ . .venv/bin/activate
$ pip3 install -r requirements.txt

$ export AWS_ACCESS_KEY_ID=""  
$ export AWS_SECRET_ACCESS_KEY=""
$ export BUCKET=""

$ python app/app.py
```

### 2. Test functions

> Upload images

```sh
$ curl --location --request POST 'http://127.0.0.1:5000/upload' --form 'file=@"/home/hungdnv9/Pictures/200846422_2973027262920842_8046046677181212054_n.jpg"'
{
  "pass": "upload image successfull"
}    
```

> GET images

```sh
$ curl --location --request GET 'http://127.0.0.1:5000/images'
{
  "items": [
    {
      "ETag": "\"3d1f4f4654824f2b1cd810d7ee9d0bce\"", 
      "Key": "Selection_126.png", 
      "LastModified": "Wed, 09 Mar 2022 11:31:01 GMT", 
      "Owner": {
        "DisplayName": "hungdnv9.cimb", 
        "ID": "8fb5349604f7f4c532bf9d447b24be9d6f4c41efacb45e633a08e2214eac95a4"
      }, 
      "Size": 43865, 
      "StorageClass": "STANDARD"
    }, 
    {
      "ETag": "\"c3ae1b5d8582345cb7360ceb7fe3283b\"", 
      "Key": "Selection_127.png", 
      "LastModified": "Wed, 09 Mar 2022 11:23:38 GMT", 
      "Owner": {
        "DisplayName": "hungdnv9.cimb", 
        "ID": "8fb5349604f7f4c532bf9d447b24be9d6f4c41efacb45e633a08e2214eac95a4"
      }, 
      "Size": 43439, 
      "StorageClass": "STANDARD"
    }
  ]
}
```

### 3. Containerized applications

```sh
$ docker-compose build
$ docker-compose up
```

## How to build up environment

### 1. Authentication and Configuration btw Terraform & AWS. Checkout detail [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

```sh
$ export AWS_ACCESS_KEY_ID=""
$ export AWS_SECRET_ACCESS_KEY=""
$ export AWS_REGION=""
```

### 2. Provision Infrastructure environment

```sh
$ cd terraform
$ terraform init
$ terraform plan
$ terraform apply
```

### 3. Clean up

```sh
$ cd terraform
$ terraform destroy
```

## Manage EKS cluster

Authenticate EKS cluster

```sh
$ aws eks --region ap-northeast-1 update-kubeconfig --name eks_cluster_1
```

Update CoreDNS

By default, CoreDNS is configured to run on Amazon EC2 infrastructure on Amazon EKS clusters  
We have to update CoreDNS can be schedule on Fargate profile  
REF: https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html


```sh
$ kubectl get pods -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
coredns-76f4967988-7hrxw   0/1     Pending   0          40m
coredns-76f4967988-z4f2s   0/1     Pending   0          40m
```

```sh
$ kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
```

```sh
$ kubectl scale deploy/coredns --replicas=1 -n kube-system
$ kubectl rollout restart deploy/coredns -n kube-system
```

```sh
$ kubectl get pods -n kube-system -o wide
NAME                       READY   STATUS    RESTARTS   AGE     IP           NODE                                                    NOMINATED NODE   READINESS GATES
coredns-5b46f5f968-d5jqh   1/1     Running   0          2m44s   10.0.2.71    fargate-ip-10-0-2-71.ap-northeast-1.compute.internal    <none>           <none>
```

Deploy Load Balancer Controller

```sh
$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::316516050658:role/eks_lb_controller
EOF

$ kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
$ helm repo add eks https://aws.github.io/eks-charts
$ helm repo update
$ helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks_cluster_1 \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set replicaCount=1 \
  --set vpcId=vpc-0bfd37f96d84bdfe1 \
  --set region=ap-northeast-1
```

```sh
$ kubectl get pods -n kube-system -o wide
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-557c948d65-6jcnn   1/1     Running   0          99s
coredns-5cbfcd5b56-b2rzg                        1/1     Running   0          160m
```

## Deploy Application

Build & Push Image to ECR

```sh
$ aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 316516050658.dkr.ecr.ap-northeast-1.amazonaws.com
$ docker build -t eks_quickstart .
$ docker tag eks_quickstart:latest 316516050658.dkr.ecr.ap-northeast-1.amazonaws.com/eks_quickstart:latest
$ docker push 316516050658.dkr.ecr.ap-northeast-1.amazonaws.com/eks_quickstart:latest
```

Deploy

```sh
$ helm upgrade --install eks-quickstart charts/eks-quickstart --create-namespace -n quickstart
```

Access API via ALB domain

```sh
$ kubectl get ingress -n quickstart
NAME             CLASS    HOSTS                    ADDRESS                                                                       PORTS   AGE
eks-quickstart   <none>   api.eks-quickstart.com   k8s-quicksta-eksquick-7f1951907f-197567907.ap-northeast-1.elb.amazonaws.com   80      32m

$ curl --location \
     -H "Host: api.eks-quickstart.com" \
     --request GET 'http://k8s-quicksta-eksquick-7f1951907f-197567907.ap-northeast-1.elb.amazonaws.com/images'
```

Debug helm

```sh
$ helm template --debug charts/eks-quickstart
$ helm install --dry-run --debug charts/eks-quickstart --generate-name
```

## Setup CICD 

Get Github Action Access key & secret key

```sh
$ terraform show -json | jq .values.outputs.github_action_access_key.value
$ terraform show -json | jq .values.outputs.github_action_secret_key.value
```

## RBAC

Setting RBAC, aws-auth configmap
```sh
$ kubectl apply -f infra/rbac/leaders.yaml
$ kubectl apply -f infra/rbac/developer.yaml
$ kubectl get cm aws-auth -o yaml -n kube-system
$ kubectl apply -f infra/rbac/aws-auth.yaml
```

```sh
$ k get role,rolebinding -n quickstart
NAME                                             CREATED AT
role.rbac.authorization.k8s.io/developers-role   2022-03-21T12:52:47Z
role.rbac.authorization.k8s.io/leader-role       2022-03-21T12:52:43Z

NAME                                                    ROLE                   AGE
rolebinding.rbac.authorization.k8s.io/developers-role   Role/developers-role   46s
rolebinding.rbac.authorization.k8s.io/leader-role       Role/leader-role       50s
```

Test permission  

~/.aws/credentials
```conf
[dev-316516050658]
aws_access_key_id = {...}
aws_secret_access_key = {...}

[leader-316516050658]
aws_access_key_id = {...}
aws_secret_access_key = {...}
```

~/.aws/config
```conf
[profile dev-316516050658]
region=ap-northeast-1

[profile leader-316516050658]
region=ap-northeast-1

[profile eks-developers-role]
role_arn = arn:aws:iam::316516050658:role/eks-developers-role
source_profile = dev-316516050658
role_session_name = dev_user1

[profile eks-leaders-role]
role_arn = arn:aws:iam::316516050658:role/eks-leader-role
source_profile = leader-316516050658
role_session_name = leader_user1
```

```sh
$ aws sts get-caller-identity --profile eks-developers-role
{
    "UserId": "AROAUTMOTU3RNB4XEJ36K:dev_user1",
    "Account": "316516050658",
    "Arn": "arn:aws:sts::316516050658:assumed-role/eks-developers-role/dev_user1"
}

$ aws sts get-caller-identity --profile eks-leaders-role
{
    "UserId": "AROAUTMOTU3RA4EOBML4P:leader_user1",
    "Account": "316516050658",
    "Arn": "arn:aws:sts::316516050658:assumed-role/eks-leader-role/leader_user1"
}
```

```sh
$ aws eks --region ap-northeast-1 update-kubeconfig --name eks_cluster_1 --profile eks-leaders-role
$ kubectl auth can-i create pods -n quickstart
yes

$ kubectl auth can-i create pods -n kube-system
no

$ kubectl auth can-i get pods -n kube-system
no
```

```sh
$ aws eks --region ap-northeast-1 update-kubeconfig --name eks_cluster_1 --profile eks-developers-role
$ kubectl auth can-i create pods -n quickstart
no

$ kubectl auth can-i create pods -n kube-system
no

$ kubectl auth can-i get pods -n kube-system
no
```
