# terraform-demo

Once you downloaded the project and filled your AWS credentials:
1. terraform init
2. terraform apply
3. ansible-playbook --private-key=my-key-private.pem -u ubuntu -i "$(terraform output master.ip)," playbook.yml

for to connect to just created AWS instance run this:
ssh -i my-key-private.pem ubuntu@"$(terraform output master.ip)"
