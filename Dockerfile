FROM aiidalab/full-stack:latest
LABEL maintainer="Daniel Hollas <daniel.hollas@bristol.ac.uk>"

USER root
WORKDIR /opt/

# NOTE: We bump traitlets package to 5.9 for performance and app loading speed.
# This is a temporary measure until we update the underlying Jupyter image.
RUN mamba install --yes -c conda-forge \
     traitlets=5.9 \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Install and configure SLURM
RUN apt-get update \
    && apt-get install --yes --no-install-recommends vim slurm-wlm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV SLURM_CONF_FILE /etc/slurm/slurm.conf

COPY --chown=slurm slurm/slurm.conf /opt/slurm.conf
RUN usermod -a -G slurm ${NB_USER}
RUN chmod a+r /opt/slurm.conf

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
