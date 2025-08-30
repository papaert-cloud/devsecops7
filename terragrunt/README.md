Terragrunt live tree for dev / test / prod

Layout:
- _global/terragrunt.hcl  : common locals and provider generation
- state-bootstrap/        : helper to create remote state S3/DynamoDB (one-time)
- <env>/region/           : environment-specific terragrunt.hcl files (remote_state + inputs)

Notes:
- I used `sandbox` for the intermediate environment (previously `test`). If you prefer `test` or another name, rename the folder under `terragrunt/`.

Next steps:
- Replace REMPLACE_ME_TFSTATE_BUCKET and table names with real values
- Add modules in `modules/` (vpc, ecs, s3-backend, etc.) or point terraform source to your module repo
- Run `terragrunt init` + `terragrunt plan` in an env folder to validate
