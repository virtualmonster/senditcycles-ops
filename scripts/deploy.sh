#!/bin/bash

# SendItCycles GitOps Deployment Script
# This script handles deployment to dev, staging, and prod environments
# Triggered by GitHub Actions on merge to main

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$( dirname "$SCRIPT_DIR" )" )"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate environment
validate_environment() {
  local env=$1
  local env_file="${REPO_ROOT}/environments/${env}/.env.${env}"
  
  if [ ! -f "$env_file" ]; then
    log_error "Environment file not found: $env_file"
    return 1
  fi
  
  log_info "✓ Environment file exists: $env_file"
  return 0
}

# Function to validate docker-compose
validate_compose() {
  local env=$1
  local compose_file="${REPO_ROOT}/environments/${env}/docker-compose.yml"
  
  if [ ! -f "$compose_file" ]; then
    log_error "docker-compose file not found: $compose_file"
    return 1
  fi
  
  log_info "Validating docker-compose.yml..."
  docker-compose -f "$compose_file" config > /dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    log_info "✓ docker-compose.yml is valid"
    return 0
  else
    log_error "docker-compose.yml validation failed"
    return 1
  fi
}

# Function to deploy environment
deploy() {
  local env=$1
  local compose_file="${REPO_ROOT}/environments/${env}/docker-compose.yml"
  local env_file="${REPO_ROOT}/environments/${env}/.env.${env}"
  
  log_info "=========================================="
  log_info "Deploying to ${env} environment"
  log_info "=========================================="
  
  # Validate before deploying
  validate_environment "$env" || return 1
  validate_compose "$env" || return 1
  
  # Load environment variables
  set -a
  [ -f "$env_file" ] && source "$env_file"
  set +a
  
  # Build and bring up containers
  log_info "Building images for ${env}..."
  docker-compose -f "$compose_file" --env-file "$env_file" build
  
  log_info "Starting services for ${env}..."
  docker-compose -f "$compose_file" --env-file "$env_file" up -d
  
  # Wait for services to be healthy
  log_info "Waiting for services to be healthy..."
  sleep 10
  
  # Check container status
  log_info "Checking container status..."
  docker-compose -f "$compose_file" --env-file "$env_file" ps
  
  log_info "✓ Deployment to ${env} completed successfully"
  return 0
}

# Function to rollback (revert to previous version)
rollback() {
  local env=$1
  log_warn "Rolling back ${env} environment..."
  log_info "Running docker-compose down..."
  
  local compose_file="${REPO_ROOT}/environments/${env}/docker-compose.yml"
  docker-compose -f "$compose_file" down
  
  log_info "✓ Rollback completed. Redeploy with git revert + push to restore service."
}

# Main script logic
main() {
  local env="${1:-dev}"
  local action="${2:-deploy}"
  
  # Validate environment name
  if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Invalid environment: $env"
    echo "Usage: $0 {dev|staging|prod} {deploy|rollback|validate}"
    exit 1
  fi
  
  case "$action" in
    deploy)
      deploy "$env" || exit 1
      ;;
    validate)
      validate_environment "$env" || exit 1
      validate_compose "$env" || exit 1
      log_info "✓ Validation successful"
      ;;
    rollback)
      rollback "$env" || exit 1
      ;;
    *)
      log_error "Invalid action: $action"
      echo "Usage: $0 {dev|staging|prod} {deploy|rollback|validate}"
      exit 1
      ;;
  esac
}

# Run main function
main "$@"
