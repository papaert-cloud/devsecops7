include { path = find_in_parent_folders() }

terraform { source = "${get_repo_root()}/modules/stacks//vpc" }

inputs = {
  name       = "test-vpc"
  cidr_block = "10.10.0.0/16"
}
