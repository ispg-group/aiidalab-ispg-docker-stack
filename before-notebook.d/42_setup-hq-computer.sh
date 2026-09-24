#!/bin/bash
# Here we setup a new AiiDA computer configured with SLURM.
# Note: We defer the AiiDA ORCA code installation for the 'post_install' script
# that is run when aiidalab-ispg app is installed.

set -euo pipefail

# Disable and rename the default 'localhost' computer to 'localhost-legacy'.
# This is necessary because we will create a new 'localhost' computer
# configured with HyperQueue as the job management system.
verdi computer disable localhost aiida@localhost
verdi computer relabel localhost localhost-legacy

computer_name=localhost

# TODO: Use YAML for the config
if ! verdi computer show $computer_name &> /dev/null; then
  verdi computer setup --non-interactive \
  --label "${COMPUTER_LABEL}"                                     \
  --description "local computer with hyperqueue scheduler"        \
  --hostname "localhost"                                          \
  --transport core.local                                          \
  --scheduler hyperqueue                                          \
  --work-dir /home/${NB_USER}/aiida_run/                          \
  --mpiprocs-per-machine 1

  verdi computer configure core.local $computer_name \
    --non-interactive --safe-interval 0.1 --use-login-shell
fi
