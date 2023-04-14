#!/bin/bash
set -em

# Auto-determine number of CPUs and RAM.
# User can also pass these via SLURM_NCPU and SLURM_MEMORY_MB env vars
if [[ -z ${SLURM_NCPU-} ]];then
  # We reserve one CPU for other processes (AiiDA daemon, jupyter, DB...) 
  NUM_PHYSICAL_CORES=$(python -c 'import psutil; print(int(psutil.cpu_count(logical=False)))' 2>/dev/null)
  if [[ $NUM_PHYSICAL_CORES -eq 1 ]]; then
    SLURM_NCPU=1
  else
    let SLURM_NCPU=NUM_PHYSICAL_CORES-1
  fi
fi
if [[ -z ${SLURM_MEMORY_MB-} ]];then
  SLURM_MEMORY_MB=$(python -c "import psutil;print(int(psutil.virtual_memory().total/1024**2))")
fi

echo "Using the following configuration for SLURM:"
echo "RAM=$SLURM_MEMORY_MB Mb  NCPU=$SLURM_NCPU"
echo "See ${SLURM_CONF_FILE} for details"

cat >> $SLURM_CONF_FILE << EOF
NodeName=localhost RealMemory=$SLURM_MEMORY_MB ThreadsPerCore=1 Sockets=1 CoresPerSocket=$SLURM_NCPU State=UNKNOWN
EOF

# Only attept to run SLURM if we're root
if [ "$(id -u)" == 0 ] ; then
  # --force needed to get rid of permission error
  # TODO: Solve it rigorously in Dockerfile
  run-one-constantly munged --force -F &
  run-one-constantly slurmctld -D &
  run-one-constantly slurmd -D &
fi
