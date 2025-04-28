# Wanderlust Mega Project End to End Implementation

### In this demo, we will see how to deploy an end to end three tier MERN stack application on EKS cluster.

#
## Tech stack used in this project:
- GitHub (Code)
- Docker (Containerization)
- Jenkins (CI)
- SonarQube (Quality)
- Trivy (Filesystem Scan)
- ArgoCD (CD)
- Redis
- AWS EKS (Kubernetes)
  - Deployments
  - Services
  - Ingress 

### Pre-requisites to implement this project:
#
- <b>Create 1 virtual machine on AWS with 2 CPU, 4GB of RAM (t2.medium) and 29 GB of storage</b>
#
- <b>Install docker</b>
```bash
sudo su
```
```bash
apt update
```
```bash
apt install docker.io -y
usermod -aG docker $USER && newgrp docker
```
#
- <b>Install and configure Jenkins</b>
```bash
sudo apt update -y
sudo apt install fontconfig openjdk-17-jre -y

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
  
sudo apt-get update -y
sudo apt-get install jenkins -y
```
#
- <b>Install and configure SonarQube</b>
```bash
docker run -itd --name SonarQube-Server -p 9000:9000 sonarqube:lts-community
```
#
- <b>Install Trivy</b>
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y
```
#
- <b>Create EKS Cluster on AWS</b>
  - IAM user with **access keys and secret access keys**
  - AWSCLI should be configured (<a href="https://github.com/DevMadhup/DevOps-Tools-Installations/blob/main/AWSCLI/AWSCLI.sh">Setup AWSCLI</a>)
  ```bash
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo apt install unzip
  unzip awscliv2.zip
  sudo ./aws/install
  aws configure
  ```

  - Install **kubectl** (<a href="https://github.com/DevMadhup/DevOps-Tools-Installations/blob/main/Kubectl/Kubectl.sh">Setup kubectl</a>)
  ```bash
  curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin
  kubectl version --short --client
  ```

  - Install **eksctl** (<a href="https://github.com/DevMadhup/DevOps-Tools-Installations/blob/main/eksctl%20/eksctl.sh">Setup eksctl</a>)
  ```bash
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin
  eksctl version
  ```
  - <b>Create EKS Cluster</b>
  ```bash
  eksctl create cluster --name=wanderlust \
                      --region=us-west-1 \
                      --version=1.30 \
                      --without-nodegroup
  ```
  - <b>Associate IAM OIDC Provider</b>
  ```bash
  eksctl utils associate-iam-oidc-provider \
    --region us-west-1 \
    --cluster wanderlust \
    --approve
  ```
  - <b>Create Nodegroup</b>
  ```bash
  eksctl create nodegroup --cluster=wanderlust \
                       --region=us-west-1 \
                       --name=wanderlust \
                       --node-type=t2.medium \
                       --nodes=2 \
                       --nodes-min=2 \
                       --nodes-max=2 \
                       --node-volume-size=29 \
                       --ssh-access \
                       --ssh-public-key=eks-nodegroup-key 
  ```
#### Note: Make sure the ssh-public-key "eks-nodegroup-key is available in your aws account"
#
- <b>Install and Configure ArgoCD </b>
  - <b>Create argocd namespace</b>
  ```bash
  kubectl create namespace argocd
  ```
  - <b>Apply argocd manifest</b>
  ```bash
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  ```
  - <b>Make sure all pods are running in argocd namespace</b>
  ```bash
  watch kubectl get pods -n argocd
  ```
  - <b>Install argocd CLI</b>
  ```bash
  curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64
  ```
  - <b>Provide executable permission</b>
  ```bash
  chmod +x /usr/local/bin/argocd
  ```
  - <b>Check argocd services</b>
  ```bash
  kubectl get svc -n argocd
  ```
  - <b>Change argocd server's service from ClusterIP to NodePort</b>
  ```bash
  kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
  ```
  - <b>Confirm service is patched or not</b>
  ```bash
  kubectl get svc -n argocd
  ```
  - <b>Fetch the initial password of argocd server</b>
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  ```
#
- <b>Setup jenkins worker node</b>
  - Create a new EC2 instance and install jenkins on it 
  ```bash
  sudo apt update -y
  sudo apt install fontconfig openjdk-17-jre -y

  sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
  
  sudo apt-get update -y
  sudo apt-get install jenkins -y
  ```
#
  - <b>ssh to jenkins worker and generate ssh keys</b>
  ```bash
  ssh-keygen
  ```
  ![image](https://github.com/user-attachments/assets/0c8ecb74-1bc5-46f9-ad55-1e22e8092198)
#
  - <b>Now move to /root/.ssh/ directory and copy the content of public key and paste to /root/.ssh/authorized_keys file.</b>
#
  - <b>Now, go to the jenkins master and navigate to <mark>Manage jenkins --> Nodes</mark>, and click on Add node </b>
    - name: Node
    - type: permanent agent
    - Number of executors: 1
    ![image](https://github.com/user-attachments/assets/8fa59360-f7c3-4267-bf63-aa932ba1500e)
    - Remote root directory
    ![image](https://github.com/user-attachments/assets/28651dda-8675-4af8-ab08-dc858ac8c589)
    - Labels: Node
    - Usage: Only build jobs with label expressions matching this node
    - Launch method: Via ssh
    - Host: <public-ip-worker-jenkins>
    - Credentials: <mark>Add --> Kind: ssh username with private key --> ID: Worker --> Description: Worker --> Username: root --> Private key: Enter directly --> Add Private key</mark>
    ![image](https://github.com/user-attachments/assets/1492fa3d-a83a-4164-b367-66d0b550f933)
    - Host Key Verification Strategy: Non verifying Verification Strategy
    - Availability: Keep this agent online as much as possible
#
  - And your jenkins worker node is added
  ![image](https://github.com/user-attachments/assets/cab93696-a4e2-4501-b164-8287d7077eef)
#
## Steps to implement the project:

