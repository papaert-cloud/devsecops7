# Makefile for CloudFormation StackSet (stackset_root)
SHELL := /usr/bin/env bash
TF ?= terraform
VAR_FILE ?= ../env/stackset.dev.tfvars

.PHONY: init reinit clean nuke fmt validate plan plan-refresh apply destroy state doctor \
        status-stackset status-ops status-instances \
        ss-get-template-summary ss-detect-drift ss-op ss-op-results ss-instance-drifts \
        ss-list-ou-accounts ss-targets-json

# ---------- Terraform lifecycle ----------
init:            ; $(TF) init
clean:           ; rm -rf .terraform
nuke:            ; rm -rf .terraform .terraform.lock.hcl
reinit: nuke     ; $(TF) init -reconfigure

fmt:             ; $(TF) fmt -recursive
validate: fmt    ; $(TF) validate
plan:            ; $(TF) plan -var-file=$(VAR_FILE) -input=false
plan-refresh:    ; $(TF) plan -refresh-only -var-file=$(VAR_FILE) -input=false
apply:           ; $(TF) apply -var-file=$(VAR_FILE) -input=false -auto-approve
destroy:         ; $(TF) destroy -var-file=$(VAR_FILE) -input=false -auto-approve
state:           ; $(TF) state list || true

doctor:
	@echo "PWD: $$(pwd)"; echo; ls -la
	@echo; echo "Terraform version:"; $(TF) version
	@echo; echo "Providers in this config:"; $(TF) providers
	@echo; echo "Using VAR_FILE=$(VAR_FILE)"

# ---------- tfvars helper ----------
define GET_TFVAR
awk -v k="$(1)" 'BEGIN{FS="="}
  $$1 ~ "^[[:space:]]*"k"[[:space:]]*$$" { next }
  $$1 ~ "^[[:space:]]*"k"[[:space:]]*" {
    sub(/^[^=]*=/,""); gsub(/^[[:space:]"]+|[[:space:]"]+$$/,""); print; exit
  }' $(VAR_FILE)
endef

# ---------- AWS CLI wrappers (StackSet) ----------
status-stackset:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation describe-stack-set \
	  --stack-set-name "$$ssn" --region "$$reg" --output table
status-ops:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation list-stack-set-operations \
	  --stack-set-name "$$ssn" --region "$$reg" --max-items 20 --output table

status-instances:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation list-stack-instances \
	  --stack-set-name "$$ssn" --region "$$reg" --output table

ss-get-template-summary:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation get-template-summary \
	  --stack-set-name "$$ssn" --region "$$reg" --output table

ss-detect-drift:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	echo "Starting StackSet drift detection for $$ssn ..."; \
	op=$$(AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation detect-stack-set-drift \
	  --stack-set-name "$$ssn" --region "$$reg" --query OperationId --output text); \
	echo "OperationId: $$op"; \
	while :; do \
	  st=$$(AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation describe-stack-set-operation \
	    --stack-set-name "$$ssn" --operation-id "$$op" --region "$$reg" --query 'StackSetOperation.Status' --output text); \
	  echo "Status: $$st"; [ "$$st" != "RUNNING" ] && break; sleep 5; \
	done; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation list-stack-set-operation-results \
	  --stack-set-name "$$ssn" --operation-id "$$op" --region "$$reg" --output table

# Inspect a specific operation (use OP=<operation-id>)
ss-op:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	: $${OP:?OP=<operation-id> is required}; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation describe-stack-set-operation \
	  --stack-set-name "$$ssn" --operation-id "$$OP" --region "$$reg" --output table

# Show per-account results for an operation (use OP=<operation-id>)
ss-op-results:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	: $${OP:?OP=<operation-id> is required}; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation list-stack-set-operation-results \
	  --stack-set-name "$$ssn" --operation-id "$$OP" --region "$$reg" --output table

# List instance resource drifts across the StackSet (may return large output)
ss-instance-drifts:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation list-stack-instance-resource-drifts \
	  --stack-set-name "$$ssn" --region "$$reg" --output table

# Show accounts under each OU provided in tfvars (mgmt acct credentials required)
ss-list-ou-accounts:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; \
	ou_raw="$$( $(call GET_TFVAR,ou_ids) )"; \
	reg="$$( $(call GET_TFVAR,region) )"; \
	prof="$$( $(call GET_TFVAR,profile) )"; \
	ou_clean=$$(echo "$$ou_raw" | sed 's/[][]//g; s/"//g; s/ //g'); \
	IFS=','; \
	for id in $$ou_clean; do \
	  id=$$(echo $$id | xargs); [ -z "$$id" ] && continue; \
	  echo "== Accounts in OU $$id =="; \
	  AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws organizations list-accounts-for-parent \
	    --parent-id "$$id" --output table || true; \
	done


# JSON view of current targets (instances) for the StackSet
ss-targets-json:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; reg="$$( $(call GET_TFVAR,region) )"; prof="$$( $(call GET_TFVAR,profile) )"; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation list-stack-instances \
	  --stack-set-name "$$ssn" --region "$$reg" \
	  --query 'Summaries[].{Account:Account,Region:Region,Status:Status,Drift:StackInstanceStatus.DetailedStatus}' --output json

# --- add beneath your GET_TFVAR def ---

import-stackset:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; \
	echo "Importing StackSet $$ssn into state..."; \
	terraform import 'module.stackset.aws_cloudformation_stack_set.this' "$$ssn"

# Imports the first OU in ou_ids as the [0] instance
import-instance:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; \
	reg="$$( $(call GET_TFVAR,region) )"; \
	call="$$( $(call GET_TFVAR,call_as) )"; \
	ou_raw="$$( $(call GET_TFVAR,ou_ids) )"; \
	ou_first=$$(echo "$$ou_raw" | sed 's/[][]//g; s/"//g; s/ //g' | awk -F, '{print $$1}'); \
	[ -z "$$call" ] && call="SELF"; \
	echo "Importing instance $$ssn,$$ou_first,$$reg,$$call"; \
	terraform import 'module.stackset.aws_cloudformation_stack_set_instance.service_managed[0]' \
	  "$$ssn,$$ou_first,$$reg,$$call"

# Danger: deletes instances, then the StackSet in AWS (outside Terraform)
ss-delete-existing:
	@ssn="$$( $(call GET_TFVAR,stack_set_name) )"; \
	reg="$$( $(call GET_TFVAR,region) )"; \
	prof="$$( $(call GET_TFVAR,profile) )"; \
	ou_raw="$$( $(call GET_TFVAR,ou_ids) )"; \
	ou_clean=$$(echo "$$ou_raw" | sed 's/[][]//g; s/"//g; s/ //g'); \
	echo "Deleting instances for $$ssn in $$reg, OUs=$$ou_clean"; \
	op=$$(AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation delete-stack-instances \
	      --stack-set-name "$$ssn" \
	      --deployment-targets OrganizationalUnitIds=$$ou_clean \
	      --regions "$$reg" \
	      --no-retain-stacks \
	      --query OperationId --output text); \
	echo "OperationId: $$op"; \
	while :; do \
	  st=$$(AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation describe-stack-set-operation \
	        --stack-set-name "$$ssn" --operation-id "$$op" --region "$$reg" \
	        --query 'StackSetOperation.Status' --output text); \
	  echo "Status: $$st"; [ "$$st" != "RUNNING" ] && break; sleep 5; \
	done; \
	echo "Deleting stack set $$ssn"; \
	AWS_PROFILE="$${prof:-$$AWS_PROFILE}" aws cloudformation delete-stack-set \
	  --stack-set-name "$$ssn"

ss-force-delete:
	@ssn="$(STACK_SET_NAME)"; \
	reg="$(AWS_REGION)"; \
	echo "Force deleting $$ssn in $$reg"; \
	op=$$(aws cloudformation delete-stack-instances \
		--stack-set-name "$$ssn" \
		--deployment-targets OrganizationalUnitIds=$(OU_IDS) \
		--regions "$$reg" \
		--no-retain-stacks \
		--query OperationId --output text); \
	echo "Delete instances op=$$op"; \
	aws cloudformation wait stack-set-operation-complete \
		--stack-set-name "$$ssn" \
		--operation-id "$$op" || true; \
	aws cloudformation delete-stack-set \
		--stack-set-name "$$ssn"

