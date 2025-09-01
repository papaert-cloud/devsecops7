include { path = find_in_parent_folders() }

terraform { source = "${get_repo_root()}/modules/stacks//ec2" }

inputs = { name_prefix = "test-ec2" }
