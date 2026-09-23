FROM aiidalab/full-stack:edge
LABEL maintainer="Daniel Hollas <daniel.hollas@bristol.ac.uk>"

USER root
WORKDIR /opt/

ARG HQ_VER=0.19.0

ARG HQ_URL_AMD64="https://github.com/It4innovations/hyperqueue/releases/download/v${HQ_VER}/hq-v${HQ_VER}-linux-x64.tar.gz"
ARG HQ_URL_ARM64="https://github.com/It4innovations/hyperqueue/releases/download/v${HQ_VER}/hq-v${HQ_VER}-linux-arm64-linux.tar.gz"
ARG AIIDA_HQ_PKG="aiida-hyperqueue~=0.3.0"

# NOTE: We could remove the OpenMPI and xTB installations as we now can
# install them directly during the aiidalab-ispg installation, see:
# https://github.com/ispg-group/aiidalab-ispg/pull/221
# but because it takes a non-trivial amount of time,
# we install them here to speed up the installation.
RUN mamba install --yes -c conda-forge \
     xtb-python \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Download and unpack the correct hq binary for the architecture:
RUN set -ex; \
    if [ "${TARGETARCH}" = "arm64" ]; then \
      wget --no-verbose -c -O hq.tar.gz "${HQ_URL_ARM64}"; \
    else \
      wget --no-verbose -c -O hq.tar.gz "${HQ_URL_AMD64}"; \
    fi && \
    tar xf hq.tar.gz -C /opt/conda/ && rm hq.tar.gz

RUN python -m pip install --no-user --no-cache-dir ${AIIDA_HQ_PKG}

COPY ./before-notebook.d/* /usr/local/bin/before-notebook.d/

WORKDIR "/home/${NB_USER}/"
