# Here we setup a new AiiDA computer configured with SLURM.
# Note: We defer the AiiDA ORCA code installation for the 'post_install' script
# that is run when aiidalab-ispg app is installed.

set -euo pipefail

computer_name=slurm

# TODO: Use YAML for the config
if ! verdi computer show $computer_name &> /dev/null; then
  verdi computer setup --non-interactive \
    --label $computer_name -H localhost -D "localhost with SLURM" \
    --scheduler core.slurm --transport core.local \
    --mpiprocs-per-machine 1 --work-dir /home/jovyan/aiida_run/

  verdi computer configure core.local $computer_name \
    --non-interactive --safe-interval 0 --use-login-shell
fi
