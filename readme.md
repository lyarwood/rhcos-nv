# CUSTOM RHCOS

Custom RHCOS image layers that replace the stock kernel with an NV kernel from a Brew task repo.

### Prepare

Set environment variables:
```sh
export RHCOS_VERSION=4.22.0-0.nightly-arm64-2026-05-11-232600
export PULL_SECRET="~/pull-secret.json"
export KERNEL_REPO="https://brew-task-repos.engineering.redhat.com/repos/official/kernel/6.12.0/225.6.el10nv_draft_4010320/kernel-6.12.0-225.6.el10nv_draft_4010320.repo"
```

For GA releases the target image is extracted from the release payload:
```sh
export TARGET_IMAGE=$(oc adm release info --image-for rhel-coreos-10 \
  "quay.io/openshift-release-dev/ocp-release:${RHCOS_VERSION}-aarch64")
```

For nightly builds, authenticate to the CI registry and use the nightly payload:
```sh
# Authenticate to the CI registry (requires a token from
# https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com/)
export KUBECONFIG=/tmp/kubeconfig.ci-only
oc login --token='<token>' --server=https://api.ci.l2s4.p1.openshiftapps.com:6443
oc registry login --to /tmp/ci-registry-auth.json
unset KUBECONFIG

# Merge CI auth with your pull secret
jq -s '.[0].auths * .[1].auths | {auths: .}' \
  $PULL_SECRET /tmp/ci-registry-auth.json > /tmp/merged-auth.json
export PULL_SECRET=/tmp/merged-auth.json

# Extract the target image from the nightly payload
export TARGET_IMAGE=$(oc adm release info --registry-config $PULL_SECRET \
  --image-for rhel-coreos-10 \
  "registry.ci.openshift.org/ocp-arm64/release-arm64:${RHCOS_VERSION}")
```

### Build OCP Container Image Layer

Both containerfiles include a multi-stage build that clones `openshift/kubernetes`
and cross-compiles kubelet for arm64. The repo and branch are configurable via
`KUBELET_REPO` and `KUBELET_BRANCH` build args (defaults: `https://github.com/openshift/kubernetes.git`
and `release-4.22`).

```sh
# Build the RHCOS image layer
podman build -f rhcos.containerfile \
  --authfile $PULL_SECRET \
  --build-arg TARGET_IMAGE=$TARGET_IMAGE \
  --build-arg KERNEL_REPO=$KERNEL_REPO \
  --tag "rhcos-cs:${RHCOS_VERSION}-latest"

# Build the 64k page size RHCOS image layer
podman build -f rhcos-64k.containerfile \
  --authfile $PULL_SECRET \
  --build-arg TARGET_IMAGE=$TARGET_IMAGE \
  --build-arg KERNEL_REPO=$KERNEL_REPO \
  --tag "rhcos-64k-cs:${RHCOS_VERSION}-latest"
```

To override the kubelet source:
```sh
podman build -f rhcos-64k.containerfile \
  --authfile $PULL_SECRET \
  --build-arg TARGET_IMAGE=$TARGET_IMAGE \
  --build-arg KERNEL_REPO=$KERNEL_REPO \
  --build-arg KUBELET_BRANCH=release-4.22 \
  --tag "rhcos-64k-cs:${RHCOS_VERSION}-latest"
```

### Build Driver Toolkit Container Image Layer

```sh
# Build the driver toolkit image (requires --platform for cross-arch builds)
podman build -f driver-toolkit.containerfile \
  --platform linux/arm64 \
  --authfile $PULL_SECRET \
  --build-arg KERNEL_REPO=$KERNEL_REPO \
  --tag "driver-toolkit-cs:${RHCOS_VERSION}-latest"
```
