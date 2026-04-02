output "bucket_names" {
  description = "Map of bucket names by course ID"
  value       = { for k, v in google_storage_bucket.course_buckets : k => v.name }
}

output "bucket_urls" {
  description = "Map of bucket URLs by course ID"
  value       = { for k, v in google_storage_bucket.course_buckets : k => v.url }
}

output "course_buckets" {
  description = "Map of course bucket names ({bucket_prefix}-{courseId})"
  value       = { for k, v in google_storage_bucket.course_buckets : k => v.name }
}
