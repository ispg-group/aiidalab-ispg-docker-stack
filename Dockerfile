FROM ubuntu:24.04 AS slurm-build
ARG SLURM_VERSION=24.11.5
RUN apt-get update && apt-get install -y build-essential fakeroot devscripts equivs curl
RUN curl -fsSL https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 | tar xj
WORKDIR /slurm-${SLURM_VERSION}
RUN mk-build-deps -i -t 'apt-get -y' debian/control && debuild -b -uc -us

FROM ubuntu:24.04

FROM aiidalab/full-stack:edge
LABEL maintainer="Daniel Hollas <daniel.hollas@bristol.ac.uk>"

USER root
WORKDIR /opt/

# Install and configure SLURM
RUN groupadd --system slurm && \
    useradd --system --gid slurm --no-create-home \
            --home-dir /var/lib/slurm --shell /usr/sbin/nologin slurm

RUN mkdir -p /var/spool/slurmd /var/lib/slurm/slurmctld /var/log/slurm && \
    chown -R slurm:slurm /var/spool/slurmd /var/lib/slurm /var/log/slurm

COPY --from=slurm-build /*.deb /tmp/debs/
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim munge \
    /tmp/debs/slurm-smd_*.deb \
    /tmp/debs/slurm-smd-slurmctld_*.deb /tmp/debs/slurm-smd-slurmd_*.deb \
    /tmp/debs/slurm-smd-client_*.deb && \
    rm -rf /tmp/debs && apt-get clean && rm -rf /var/lib/apt/lists/*

# This should silence MPI/PMIX plugin errors at slurmd/slurmctld startup
RUN rm -f /usr/lib/x86_64-linux-gnu/slurm/mpi_pmix*.so

ENV SLURM_PATH=/etc/slurm/

COPY --chown=slurm slurm/* /opt/
RUN usermod -a -G slurm ${NB_USER}
RUN chmod a+r /opt/*.conf

RUN mkdir /run/munge
RUN chown -R root /etc/munge /var/lib/munge

# Copy script to start SLURM daemons
# NOTE: It is imperative to copy this script into the
# start-notebook.d/ directory, where the scripts might
# be executed by root user.
# Scripts in before-notebook.d/ must be executed by ${NB_USER}
# For this to work, we need to patch the start.sh script, see below.
COPY --chown=${NB_USER}:users slurm/slurm-service.sh /usr/local/bin/start-notebook.d/10_slurm-service.sh
# Patch the start.sh script to run hooks under NB_USER
# even if called with root user
COPY jupyter-start.sh /usr/local/bin/start.sh

# NOTE: This script sets up the slurm computer in AiiDA DB
# so it needs to run before 60_prepare-aiidalab.sh,
# which installs the aiidalab-ispg, which in turn installs the orca code nodes.
COPY opt/setup-ispg-things.sh /usr/local/bin/before-notebook.d/59_setup-ispg-things.sh
RUN chmod a+r /usr/local/bin/before-notebook.d/59_setup-ispg-things.sh
WORKDIR "/home/${NB_USER}/"
