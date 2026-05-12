ARG GOLANG_IMAGE=registry.access.redhat.com/ubi10/go-toolset:latest
ARG TARGET_IMAGE

FROM ${GOLANG_IMAGE} AS kubelet-builder

ARG KUBELET_REPO=https://github.com/openshift/kubernetes.git
ARG KUBELET_BRANCH=release-4.22

USER root
RUN git clone --depth 1 --branch ${KUBELET_BRANCH} ${KUBELET_REPO} /build/kubernetes
WORKDIR /build/kubernetes
RUN export KUBE_GIT_VERSION=$(sed -rn 's/.*io.openshift.build.versions="kubernetes=(1.[0-9]+.[0-9]+)"/v\1/p' openshift-hack/images/hyperkube/Dockerfile.rhel) && \
  export KUBE_GIT_COMMIT=$(git rev-parse HEAD) && \
  export KUBE_GIT_MAJOR=$(echo $KUBE_GIT_VERSION | sed -E 's/v([0-9]+)\..*/\1/') && \
  export KUBE_GIT_MINOR=$(echo $KUBE_GIT_VERSION | sed -E 's/v[0-9]+\.([0-9]+)\..*/\1/') && \
  CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
    -ldflags "-X k8s.io/component-base/version.gitVersion=${KUBE_GIT_VERSION} \
              -X k8s.io/component-base/version.gitCommit=${KUBE_GIT_COMMIT} \
              -X k8s.io/component-base/version.gitMajor=${KUBE_GIT_MAJOR} \
              -X k8s.io/component-base/version.gitMinor=${KUBE_GIT_MINOR} \
              -X k8s.io/component-base/version.gitTreeState=clean \
              -X k8s.io/component-base/version.buildDate=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
              -X k8s.io/client-go/pkg/version.gitVersion=${KUBE_GIT_VERSION} \
              -X k8s.io/client-go/pkg/version.gitCommit=${KUBE_GIT_COMMIT} \
              -X k8s.io/client-go/pkg/version.gitMajor=${KUBE_GIT_MAJOR} \
              -X k8s.io/client-go/pkg/version.gitMinor=${KUBE_GIT_MINOR} \
              -X k8s.io/client-go/pkg/version.gitTreeState=clean \
              -X k8s.io/client-go/pkg/version.buildDate=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    -o /build/kubelet ./cmd/kubelet

FROM ${TARGET_IMAGE} AS base

ARG KERNEL_REPO

RUN \
  curl ${KERNEL_REPO} > /etc/yum.repos.d/kernel.repo && \
  echo 'sslverify=0' >> /etc/yum.repos.d/kernel.repo

RUN dnf remove -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra && \
  dnf install --disablerepo="*" --enablerepo="*el10nv*" -y \
  kernel \
  kernel-core \
  kernel-modules \
  kernel-modules-core \
  kernel-modules-extra \
  && \
  dnf clean all

COPY --from=kubelet-builder /build/kubelet /usr/bin/kubelet

RUN \
  rm -rf /var/cache/* /var/log/* /etc/machine-id && \
  update-pciids && \
  ostree container commit
