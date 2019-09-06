# terraform-sqs-module

Terraform module for SQS creation with optional redrive policy (dead-letter SQS attached).

Currently it is facing an issue when first provisioned with DLQ and then DLQ is turned off. 

E.g. first use this module as: 

``` 
module "queue" {
  source = "./modules/sqs"

  queue_name                = var.queue_name
  attach_dead_letter_config = false
}
```
Apply configuration: 

```bash
terraform init
terraform workspace new dev
terraform workspace select dev
terraform apply
```

Then after the plan was applied change it to: 

``` 
module "queue" {
  source = "./modules/sqs"

  queue_name                = var.queue_name
}
```
Run terraform plan: 

```bash
terraform plan
```

Running plan will throw an error: 

```bash 

module.queue.data.aws_caller_identity.current: Refreshing state...
module.queue.data.aws_region.current: Refreshing state...
module.queue.aws_sqs_queue.regular_queue[0]: Refreshing state... [id=https://sqs.us-east-1.amazonaws.com/763369520800/test_queue-dev]

Error: Invalid index

  on modules/sqs/sqs.tf line 67, in resource "aws_sqs_queue" "regular_queue_with_dl":
  67:   redrive_policy             = var.attach_dead_letter_config ? data.template_file.regular_queue_redrive_policy[count.index].rendered : null
    |----------------
    | count.index is 0
    | data.template_file.regular_queue_redrive_policy is empty tuple

The given key does not identify an element in this collection value.


```


I've tested it with the following provider versions: 

``` 
* provider.aws: version = "~> 2.27"
* provider.template: version = "~> 2.1"
```

