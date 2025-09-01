include { path = find_in_parent_folders() }

terraform { source = "${get_repo_root()}/modules/stacks//s3" }

inputs = { bucket_name = "prod-s3-bucket" }
