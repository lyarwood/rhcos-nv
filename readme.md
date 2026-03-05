# CUSTOM RHCOS


### Prepare
Set envrioment variables
```sh
export RHCOS_VERSION=4.21.3
# OpenShift Pull Secret
export PULL_SECRET="~/pull-secret.json"
```
### Build OCP Container Image Layer
Set Image target
```sh
# Get the target image
export TARGET_IMAGE=$(oc adm release info --image-for rhel-coreos-10 "quay.io/openshift-release-dev/ocp-release:"$RHCOS_VERSION"-aarch64")

# Set the kernel repo
export KERNEL_REPO=<kernel repo>

# Build your own OCP container image layer
podman build -f rhcos.containerfile \
          --authfile $PULL_SECRET \
          --build-arg TARGET_IMAGE=$TARGET_IMAGE \
          --build-arg KERNEL_REPO=$KERNEL_REPO \
          --tag "rhcos-cs:$RHCOS_VERSION-latest"

# Build your own 64k OCP container image layer
podman build -f rhcos-64k.containerfile \
          --authfile $PULL_SECRET \
          --build-arg TARGET_IMAGE=$TARGET_IMAGE \
          --build-arg KERNEL_REPO=$KERNEL_REPO \
          --tag "rhcos-64k-cs:$RHCOS_VERSION-latest"
```

### Build Driver Toolkit Container Image Layer
```sh
# Build your own driver toolkit image
podman build -f driver-toolkit.containerfile \
          --authfile $PULL_SECRET \
          --build-arg KERNEL_REPO=$KERNEL_REPO \
          --tag "driver-toolkit-cs:$RHCOS_VERSION-latest"
```
