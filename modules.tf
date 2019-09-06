module "queue" {
  source = "./modules/sqs"

  queue_name                = var.queue_name
  attach_dead_letter_config = false
}