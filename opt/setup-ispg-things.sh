# Note: We defer the orca code installation for the post_install script
# that should be run after aiidalab-ispg app is installed.

set -euo pipefail

# However, we do setup a new computer configured with SLURM.
computer_name=slurm

if ! verdi computer show $computer_name &> /dev/null; then
  verdi computer setup --non-interactive \
    --label $computer_name -H localhost -D "localhost with SLURM" \
    --scheduler slurm --transport local \
    --mpiprocs-per-machine 1 --work-dir /home/aiida/aiida_run/

  verdi computer configure local $computer_name \
    --non-interactive --safe-interval 0 --use-login-shell
fi
