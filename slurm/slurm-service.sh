#!/bin/bash
set -eum

if [[ -z ${SLURM_CONF_FILE-} ]];then
  SLURM_CONF_FILE="/etc/slurm/slurm.conf"
fi

# Auto-determine number of CPUs and RAM.
# User can also pass these via SLURM_NCPU and SLURM_MEMORY_MB env vars.
if [[ -z ${SLURM_NCPU-} ]];then
  # We reserve one CPU for other processes (AiiDA daemon, jupyter, DB...) 
  NUM_PHYSICAL_CORES=$(python -c 'import psutil; print(int(psutil.cpu_count(logical=False)))')
  if [[ -z ${NUM_PHYSICAL_CORES-} ]]; then
    echo "WARNING: Could not determine number of CPUs. Setting NCPU in SLURM config to 1."
    SLURM_NCPU=1
  elif [[ $NUM_PHYSICAL_CORES -eq 1 ]]; then
    SLURM_NCPU=1
  else
    (( SLURM_NCPU=NUM_PHYSICAL_CORES-1 ))
  fi
fi

if [[ -z ${SLURM_MEMORY_MB-} ]];then
  SLURM_MEMORY_MB=$(python -c "import psutil;print(int(psutil.virtual_memory().total/1024**2))")
  if [[ -z ${SLURM_MEMORY_MB-} ]]; then
    echo "WARNING: Could not determine RAM size. Setting memory in SLURM to 1Gb."
    SLURM_MEMORY_MB=1000
  fi
fi

echo "Using the following configuration for SLURM:"
echo "RAM: ${SLURM_MEMORY_MB}Mb  NCPU: ${SLURM_NCPU}"
echo "See ${SLURM_CONF_FILE} for details"

if [[ ! -f $SLURM_CONF_FILE ]];then
  echo "ERROR: $SLURM_CONF_FILE does not exist!"
  exit 1
fi

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
