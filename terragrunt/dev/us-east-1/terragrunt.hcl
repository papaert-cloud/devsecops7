# Parent for dev/us-east-1 - include _global and provide any per-region overrides
include {
  path = find_in_parent_folders()
}

# Optional region-level locals
locals {
  region = "us-east-1"
}
