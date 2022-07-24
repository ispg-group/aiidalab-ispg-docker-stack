FROM aiidalab/aiidalab-docker-stack:develop
LABEL maintainer="Daniel Hollas <daniel.hollas@bristol.ac.uk>"

USER root
WORKDIR /opt/

# xtb-python is not published on PyPI so we need to install here via conda
RUN conda install --yes -c conda-forge xtb-python

# Install and configure SLURM
RUN apt-get update && apt-get install --yes slurm-wlm
COPY opt/slurm.conf /etc/slurm-llnl/slurm.conf
RUN mkdir /run/munge

# Prepare user's folders for AiiDAlab launch.
COPY opt/setup_ispg_things.sh /opt/

# NOTE: This script sets up the slurm computer in AiiDA DB
# so it needs to run before 80_prepare-aiidalab.sh,
# which installs the aiidalab-ispg, which installs the orca code nodes.
COPY my_init.d/setup_ispg_things.sh /etc/my_init.d/79_setup_ispg_things.sh

# Not sure why we need this here while it is not needed in aiidalab-docker-stack
RUN chmod a+rx /opt/setup_ispg_things.sh

CMD ["/sbin/my_my_init"]
