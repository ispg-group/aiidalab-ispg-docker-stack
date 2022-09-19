FROM aiidalab/full-stack:edge
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
COPY --chown=slurm opt/slurm.conf /etc/slurm/slurm.conf
# This is needed for aiida user to be able to access SLURM.
# Perhaps we should add aiida user to slurm group.
RUN chmod a+r /etc/slurm/slurm.conf

RUN mkdir /run/munge

# Copy scripts to start SLURM daemons
COPY service/munged /etc/service/munged/run
COPY service/slurmctld /etc/service/slurmctld/run
COPY service/slurmd /etc/service/slurmd/run

# Copy in SSL certificate and private key
# WARNING: This assumes that the Docker image is build locally and never published!!!
COPY certificates/localhost.crt /opt/certificates/localhost.crt
COPY certificates/localhost.key /opt/certificates/localhost.key
# TODO: Figure out a better way!
RUN chmod a+r /opt/certificates/localhost.crt /opt/certificates/localhost.key

# Start Jupyter notebook with HTTPS
# TODO: Needs to be replaced by something else
#COPY opt/start-notebook.sh /opt/

# NOTE: This script sets up the slurm computer in AiiDA DB
# so it needs to run before 60_prepare-aiidalab.sh,
# which installs the aiidalab-ispg, which in turn installs the orca code nodes.
COPY opt/setup-ispg-things.sh /usr/local/bin/before-notebook.d/59_setup-ispg-things.sh

RUN chmod a+rx /usr/local/bin/before-notebook.d/59_setup-ispg-things.sh

USER ${NB_USER}
WORKDIR "/home/${NB_USER}/"
