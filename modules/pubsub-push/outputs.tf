output "topic_id" {
  description = "Full resource ID of the Pub/Sub topic"
  value       = google_pubsub_topic.topic.id
}

output "topic_name" {
  description = "Name of the Pub/Sub topic"
  value       = google_pubsub_topic.topic.name
}

output "subscription_id" {
  description = "Full resource ID of the Pub/Sub subscription"
  value       = google_pubsub_subscription.push_subscription.id
}

output "subscription_name" {
  description = "Name of the Pub/Sub subscription"
  value       = google_pubsub_subscription.push_subscription.name
}

output "dead_letter_topic_id" {
  description = "Full resource ID of the dead letter topic"
  value       = var.enable_dlq ? google_pubsub_topic.dead_letter_topic[0].id : null
}

output "dead_letter_subscription_id" {
  description = "Full resource ID of the dead letter subscription"
  value       = var.enable_dlq ? google_pubsub_subscription.dead_letter_subscription[0].id : null
}

output "dead_letter_topic_name" {
  description = "Name of the dead letter topic"
  value       = var.enable_dlq ? google_pubsub_topic.dead_letter_topic[0].name : null
}
