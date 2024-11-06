TMUXP_FILE="${HOME}/.config/tmuxp/${1}.yaml"
if [ -f $TMUXP_FILE ]; then
  tmuxp load $1
else
  sesh connect $1
fi
