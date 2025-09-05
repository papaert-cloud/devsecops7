// ...copied from infra/modules/stacks/outputs.tf
output "stack_id"   { value = aws_cloudformation_stack.this.id }
output "stack_name" { value = aws_cloudformation_stack.this.name }
output "outputs"    { value = aws_cloudformation_stack.this.outputs }
