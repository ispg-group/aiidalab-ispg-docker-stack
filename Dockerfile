FROM aiidalab/aiidalab-docker-stack:latest
LABEL maintainer="Daniel Hollas <daniel.hollas@bristol.ac.uk>"

USER root
WORKDIR /opt/

# xtb-python is not published on PyPI so we need to install here via conda
RUN conda install --yes -c conda-forge xtb-python

# Install and configure SLURM
RUN apt-get update && apt-get install --yes slurm-wlm \
  && rm -rf /var/lib/apt/lists/*
# Not sure if this is needed
RUN apt-get autoremove && apt-get autoclean && apt-get clean

COPY opt/slurm.conf /etc/slurm-llnl/slurm.conf
RUN mkdir /run/munge

# Copy scripts to start SLURM daemons
COPY service/munged /etc/service/munged/run
COPY service/slurmctld /etc/service/slurmctld/run
COPY service/slurmd /etc/service/slurmd/run

# In case we need the latest aiidalab
# This might conflict with the AiiDAlab docker image
# so possibly not a good idea
#RUN pip install --upgrade aiidalab

# Prepare user's folders for AiiDAlab launch.
COPY opt/setup-ispg-things.sh /opt/

# NOTE: This script sets up the slurm computer in AiiDA DB
# so it needs to run before 80_prepare-aiidalab.sh,
# which installs the aiidalab-ispg, which in turn installs the orca code nodes.
COPY my_init.d/setup-ispg-things.sh /etc/my_init.d/79_setup-ispg-things.sh

# Not sure why we need this here while it is not needed in aiidalab-docker-stack
RUN chmod a+rx /opt/setup-ispg-things.sh

CMD ["/sbin/my_my_init"]
