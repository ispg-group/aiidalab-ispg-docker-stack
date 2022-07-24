FROM aiidalab/aiidalab-docker-stack:develop

USER root

# Install Python packages needed for AiiDAlab and populate reentry cache for root (https://pypi.python.org/pypi/reentry/).
#COPY requirements.txt .
#RUN pip install --upgrade pip
#RUN pip install -r requirements.txt
#RUN reentry scan

# xtb-python is not published on PyPI so we need to install here via conda
RUN conda install xtb-python

# Prepare user's folders for AiiDAlab launch.
COPY opt/setup_ispg_things.sh /opt/
COPY my_init.d/setup_ispg_things.sh /etc/my_init.d/90_setup_ispg_things.sh

CMD ["/sbin/my_my_init"]
