FROM aiidalab/full-stack:latest
LABEL maintainer="Daniel Hollas <daniel.hollas@bristol.ac.uk>"

USER root
WORKDIR /opt/

# xtb-python is not published on PyPI so we need to install here via conda
# We're also installing OpenMPI for ORCA parallelization,
# Concretely version specific to ORCA5
RUN conda install --yes -c conda-forge xtb-python openmpi=4.1.1

# Install and configure SLURM
RUN apt-get update && apt-get install --yes slurm-wlm \
  && rm -rf /var/lib/apt/lists/*
COPY --chown=slurm slurm/slurm.conf /etc/slurm-llnl/slurm.conf
RUN usermod -a -G slurm ${NB_USER}
RUN chmod a+r /etc/slurm-llnl/slurm.conf

RUN mkdir /run/munge

# Copy script to start SLURM daemons
# NOTE: It is imperative to copy this script into the
# start-notebook.d/ directory, where the scripts might
# be executed by root user.
# Scripts in before-notebook.d/ must be executed by ${NB_USER}
# For this to work, we need to patch the start.sh script, see below.
COPY slurm/slurm-service.sh /usr/local/bin/start-notebook.d/10_slurm-service.sh
# Patch the start.sh script to run hooks under NB_USER
# even if called with root user
COPY jupyter-start.sh /usr/local/bin/start.sh

# Copy in SSL certificate and private key
# WARNING: This assumes that the Docker image is build locally and never published!!!
COPY certificates/localhost.crt /opt/certificates/localhost.crt
COPY certificates/localhost.key /opt/certificates/localhost.key
# TODO: Figure out a better way!
RUN chmod a+r /opt/certificates/localhost.crt /opt/certificates/localhost.key

# NOTE: This script sets up the slurm computer in AiiDA DB
# so it needs to run before 60_prepare-aiidalab.sh,
# which installs the aiidalab-ispg, which in turn installs the orca code nodes.
COPY opt/setup-ispg-things.sh /usr/local/bin/before-notebook.d/59_setup-ispg-things.sh
RUN chmod a+r /usr/local/bin/before-notebook.d/59_setup-ispg-things.sh

USER ${NB_USER}
WORKDIR "/home/${NB_USER}/"
