#!/usr/bin/env bash
# deploy.sh — Test environment deployment (OPTIONAL)
#
# This is an example deployment script for Docker + K8s workflows.
# It is NOT part of the default pipeline — invoke it explicitly when needed.
# For other deployment targets (serverless, bare metal, etc.), replace or
# adapt this script to your infrastructure.
#
# Reads manifest.yaml deploy section for Docker/K8s config.
#
# Usage:
#   deploy.sh test      — Deploy to test environment
#   deploy.sh rollback  — Rollback to previous version
#   deploy.sh status    — View deployment status
#
# Prerequisites: docker, kubectl
# Exit codes: 0=success, 1=failure
source "$(dirname "$0")/../_lib.sh"

ACTION="${1:?Usage: deploy.sh <test|staging|rollback|status>}"
ENV="${ACTION}"

REGISTRY=$(manifest_get ".deploy.registry")
PROJECT_NAME=$(manifest_get ".project.name")
GIT_SHA=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
IMAGE="${REGISTRY}/${PROJECT_NAME}:${GIT_SHA}"

DOCKERFILE=$(manifest_get ".deploy.docker.dockerfile")
DOCKERFILE="${DOCKERFILE:-deploy/Dockerfile}"

echo "══════════════════════════════════"
echo "Lattice — Deploy ($ACTION)"
echo "Project: $PROJECT_NAME | SHA: $GIT_SHA"
echo "══════════════════════════════════"
echo ""

case "$ACTION" in
  test|staging)
    NAMESPACE=$(manifest_get ".deploy.environments.${ENV}.namespace")
    MANIFESTS=$(manifest_get ".deploy.environments.${ENV}.manifests")
    ROLLBACK_MODE=$(manifest_get ".deploy.environments.${ENV}.rollback")
    SMOKE=$(manifest_get ".deploy.environments.${ENV}.smoke_after_deploy")

    echo "🐳 Step 1: Docker Build"
    echo "  Image: $IMAGE"
    if [[ -f "$PROJECT_ROOT/$DOCKERFILE" ]]; then
      docker build -t "$IMAGE" -f "$PROJECT_ROOT/$DOCKERFILE" "$PROJECT_ROOT"
      pass "Docker build complete"
    else
      fail "Dockerfile not found: $DOCKERFILE"
      exit 1
    fi

    echo ""
    echo "📤 Step 2: Docker Push"
    docker push "$IMAGE"
    pass "Push complete: $IMAGE"

    echo ""
    echo "🚀 Step 3: Deploy to $ENV (namespace: $NAMESPACE)"
    if [[ -d "$PROJECT_ROOT/$MANIFESTS" ]]; then
      kubectl -n "$NAMESPACE" set image deployment/"$PROJECT_NAME" "$PROJECT_NAME=$IMAGE"
      echo "  → Waiting for rollout..."
      if kubectl -n "$NAMESPACE" rollout status deployment/"$PROJECT_NAME" --timeout=120s; then
        pass "Deployment successful"
      else
        fail "Deployment timed out"
        if [[ "$ROLLBACK_MODE" == "auto" ]]; then
          echo ""
          echo "🔄 Auto-rollback..."
          kubectl -n "$NAMESPACE" rollout undo deployment/"$PROJECT_NAME"
          warn "Auto-rollback complete"
        fi
        exit 1
      fi
    else
      fail "K8s manifests directory not found: $MANIFESTS"
      exit 1
    fi

    if [[ "$SMOKE" == "true" ]]; then
      echo ""
      echo "🔥 Step 4: Smoke Test"
      SMOKE_CMD=$(manifest_get_cmd "commands.smoke_test")
      if [[ -n "$SMOKE_CMD" ]]; then
        if run_cmd "$SMOKE_CMD"; then
          pass "Smoke test passed"
        else
          fail "Smoke test failed"
          if [[ "$ROLLBACK_MODE" == "auto" ]]; then
            echo ""
            echo "🔄 Auto-rollback..."
            kubectl -n "$NAMESPACE" rollout undo deployment/"$PROJECT_NAME"
            warn "Auto-rollback complete"
          fi
          exit 1
        fi
      else
        skip "No smoke_test command configured"
      fi
    fi
    ;;

  rollback)
    NAMESPACE=$(manifest_get ".deploy.environments.test.namespace")
    echo "🔄 Rolling back deployment/$PROJECT_NAME in $NAMESPACE"
    kubectl -n "$NAMESPACE" rollout undo deployment/"$PROJECT_NAME"
    kubectl -n "$NAMESPACE" rollout status deployment/"$PROJECT_NAME" --timeout=60s
    pass "Rollback complete"
    ;;

  status)
    NAMESPACE=$(manifest_get ".deploy.environments.test.namespace")
    echo "📊 Deployment Status"
    kubectl -n "$NAMESPACE" get deployment "$PROJECT_NAME" -o wide
    echo ""
    kubectl -n "$NAMESPACE" get pods -l "app=$PROJECT_NAME"
    ;;

  *)
    echo "Unknown action: $ACTION"
    echo "Usage: deploy.sh <test|staging|rollback|status>"
    exit 1
    ;;
esac

echo ""
echo "══════════════════════════════════"
echo "✅ Deploy $ACTION complete"
