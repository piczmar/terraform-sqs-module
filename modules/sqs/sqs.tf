variable "queue_name" {}
variable "attach_dead_letter_config" {
  default = true
}
variable "receive_wait_time_seconds" {
  default = 15
}
variable "max_receive_count" {
  default = 3
}
variable "visibility_timeout_seconds" {
  default = 180
}
# two weeks
variable "message_retention_seconds" {
  default = 1209600
}
variable "dlq_message_retention_seconds" {
  default = 1209600
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-----------------------------------
#      DLQ
#-----------------------------------

resource "aws_sqs_queue" "dead_letter_queue" {
  count = var.attach_dead_letter_config ? 1 : 0

  name                      = "${var.queue_name}-dlq-${terraform.workspace}"
  message_retention_seconds = var.dlq_message_retention_seconds
}

#-----------------------------------
#    Regular Queue
#-----------------------------------
resource "aws_sqs_queue" "regular_queue" {
  count = var.attach_dead_letter_config ? 0 : 1

  name                       = "${var.queue_name}-${terraform.workspace}"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  message_retention_seconds  = var.message_retention_seconds

  tags = {
    Env = terraform.workspace
  }
}
resource "aws_sqs_queue" "regular_queue_with_dl" {
  count = var.attach_dead_letter_config ? 1 : 0

  name                       = "${var.queue_name}-${terraform.workspace}"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  redrive_policy             = var.attach_dead_letter_config ? templatefile(
  "${path.module}/queue-redrive-policy.json.tpl", {
    dead_letter_target_arn = aws_sqs_queue.dead_letter_queue[count.index].arn
    max_receive_count      = var.max_receive_count
  }) : null
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  message_retention_seconds  = var.message_retention_seconds

  tags = {
    Env = terraform.workspace
  }
}

#--------------------------------------------------------------
# Outputs
#--------------------------------------------------------------

output "queue_arn" {
  value = element(concat(aws_sqs_queue.regular_queue.*.arn, aws_sqs_queue.regular_queue_with_dl.*.arn), 0)
}
output "queue_name" {
  value = element(concat(aws_sqs_queue.regular_queue.*.name, aws_sqs_queue.regular_queue_with_dl.*.name), 0)
}
output "queue_id" {
  value = element(concat(aws_sqs_queue.regular_queue.*.name, aws_sqs_queue.regular_queue_with_dl.*.id), 0)
}