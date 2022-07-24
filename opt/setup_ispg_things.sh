computer_name=localhost
code_name=orca

verdi code show ${code_name}@${computer_name} || verdi code setup \
    --non-interactive                                             \
    --label ${code_name}                                          \
    --description "${code_name} code connected via docker volume."\
    --input-plugin orca_main                                      \
    --computer ${computer_name}                                   \
    --remote-abs-path `which ${code_name}`

# TODO: Configure a new computer with SLURM manager and install orca code on it
