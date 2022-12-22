#!/bin/bash
set -exm

# Only attept to run SLURM if we're root
if [ "$(id -u)" == 0 ] ; then
  # --force needed to get rid of permission error
  # TODO: Solve it rigorously in Dockerfile
  run-one-constantly munged --force -F &
  run-one-constantly slurmctld -D &
  run-one-constantly slurmd -D &
fi
