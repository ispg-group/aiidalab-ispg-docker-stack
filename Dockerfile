FROM aiidalab/aiidalab-docker-stack:21.10.1

USER root

# Install Python packages needed for AiiDAlab and populate reentry cache for root (https://pypi.python.org/pypi/reentry/).
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN reentry scan

# Install dev version of cclib to be able
# to parse TDDFT from ORCA-5.0
RUN git clone https://github.com/cclib/cclib /opt/cclib
RUN cd /opt/cclib/ && pip install .

# Install simulation engines.

# TODO: Install aiida-orca
# For dev environemnt, clone and pip-install
RUN git clone https://github.com/pzarabadip/aiida-orca /opt/aiida-orca
RUN cd /opt/aiida-orca/ && pip install -e .

# Prepare user's folders for AiiDAlab launch.
COPY opt/setup_optional_things.sh /opt/
COPY my_init.d/setup_optional_things.sh /etc/my_init.d/90_setup_optional_things.sh

CMD ["/sbin/my_my_init"]
