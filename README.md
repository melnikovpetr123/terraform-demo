# terraform-demo

Once you downloaded the project and filled your AWS credentials in variables.tf:
```
# terraform init
# terraform apply
# ansible-playbook --private-key=my-key-private.pem -u ubuntu -i "$(terraform output master.ip)," playbook.yml
```

for to connect to just created AWS instance run this:
```
# ssh -i my-key-private.pem ubuntu@"$(terraform output master.ip)"
```

in case you want to apply/re-apply your TF config using a custom destination for the reverse-proxy (for example http://bit.do/) run this:
```
# terraform apply -var 'what_to_proxy="http:\\/\\/bit.do\\/"'
# ansible-playbook --private-key=my-key-private.pem -u ubuntu -i "$(terraform output master.ip)," playbook.yml
```
