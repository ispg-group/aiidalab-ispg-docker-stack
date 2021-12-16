computer_name=localhost

echo 'export PATH=/opt/orca/:$PATH' >> /home/${SYSTEM_USER}/.bashrc

for code_name in orca;
do
  verdi code show ${code_name}@${computer_name} || verdi code setup \
      --non-interactive                                             \
      --label ${code_name}                                          \
      --description "${code_name} code connected via docker volume."\
      --input-plugin orca.main                                      \
      --computer ${computer_name}                                   \
      --remote-abs-path `which ${code_name}`
done

# TODO: Configure AiiDa lab localhost computer to use SLURM manager
