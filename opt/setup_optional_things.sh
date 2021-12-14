# TODO: Setup ORCA code here
# we well need to know beforehand where the orca binary is located,
# so we probably need to have a fixed volume with orca connected to container.
computer_name=localhost

# TODO: Add orca to PATH here

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

# Uninstall aiidalab from user packages (if present).
# Would otherwise interfere with the system package.
# Can be removed after fix of: https://github.com/aiidalab/aiidalab/issues/220
USER_AIIDALAB_PACKAGE="$(python -c 'import site; print(site.USER_SITE)')/aiidalab"
if [ -e ${USER_AIIDALAB_PACKAGE} ]; then
  echo "Uninstall local installation of aiidalab package."
  /opt/conda/bin/python -m pip uninstall --yes aiidalab
fi
