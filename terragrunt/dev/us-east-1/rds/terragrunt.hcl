include { path = find_in_parent_folders() }

terraform { source = "${get_repo_root()}/modules/stacks//rds" }

inputs = { db_name = "devdb" }
