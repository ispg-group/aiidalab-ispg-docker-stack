FROM aiidalab/full-stack:latest
LABEL maintainer="Daniel Hollas <daniel.hollas@bristol.ac.uk>"

USER root
WORKDIR /opt/

# xtb-python is not published on PyPI so we need to install here via conda
# We're also installing OpenMPI for ORCA parallelization,
# concretely version specific to ORCA-5.0.3
#
# Note that for ORCA we could also create a separate
# conda environment and activate it before the code is run in the workflow.
# This wouldn't work for xtb-python, which is needed
# in the default conda environment, since it is not used
# through an AiiDA workflow, but directly from AiiDAlab UI.
RUN mamba install --yes -c conda-forge xtb-python openmpi=4.1.1 \
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

ENV NOTEBOOK_ARGS \
     "${NOTEBOOK_ARGS}" \
     "--MappingKernelManager.buffer_offline_messages=True" \
     "--MappingKernelManager.cull_busy=True" \
     "--MappingKernelManager.cull_connected=True" \
     "--MappingKernelManager.cull_idle_timeout=64800" \
     "--MappingKernelManager.cull_interval=300" \
     "--TerminalManager.cull_inactive_timeout=600" \
     "--TerminalManager.cull_interval=60"

WORKDIR "/home/${NB_USER}/"
