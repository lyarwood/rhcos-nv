ARG TARGET_IMAGE

FROM ${TARGET_IMAGE} AS base

ARG KERNEL_REPO

RUN \
  curl ${KERNEL_REPO} > /etc/yum.repos.d/kernel.repo && \
  echo 'sslverify=0' >> /etc/yum.repos.d/kernel.repo

RUN dnf remove -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra && \
  dnf install --disablerepo="*" --enablerepo="*el10nv" -y \
  kernel-64k \
  kernel-64k-core \
  kernel-64k-modules \
  kernel-64k-modules-core \
  kernel-64k-modules-extra \
  && \
  dnf clean all

RUN \
  rm -rf /var/cache/* /var/log/* /etc/machine-id && \
  update-pciids && \
  ostree container commit
