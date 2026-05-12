ARG GOLANG_IMAGE=registry.access.redhat.com/ubi10/go-toolset:latest
ARG TARGET_IMAGE

FROM ${GOLANG_IMAGE} AS kubelet-builder

ARG KUBELET_REPO=https://github.com/openshift/kubernetes.git
ARG KUBELET_BRANCH=release-4.22

USER root
RUN git clone --depth 1 --branch ${KUBELET_BRANCH} ${KUBELET_REPO} /build/kubernetes
WORKDIR /build/kubernetes
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o /build/kubelet ./cmd/kubelet

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
