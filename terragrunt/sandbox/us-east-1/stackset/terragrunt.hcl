include { path = find_in_parent_folders() }

terraform { source = "${get_repo_root()}/modules/stackset_cfn" }

inputs = { env = "sandbox" }
