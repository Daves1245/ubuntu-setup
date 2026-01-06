#!/bin/bash
set -e

echo "Warning! This will make potentially damaging changing to your $HOME directory."
echo "Please review the contents of ./ubuntu-setup.sh before running this script"
echo "Do not run as root, we call sudo inside of this script when needed."
echo "Make sure to run this script from the directory that the script is located in"
echo "Continue? (y/n)"
read -rp "" input
if [[ ! "$input" =~ ^[yY](es)?$ ]]; then
  echo "Script cancelled..."
  exit 1
fi

# Install desired programs
sudo add-apt-repository ppa:slimbook/slimbook
sudo apt update
sudo apt install slimbookbattery speedtest-cli bbswitch-dkms -y

# Copy the binaries directory
cp -r ./bin ~/bin
# Add ~/bin path to bashrc, with highest priority (earliest in path)
cat >>~/.bashrc <<EOF
# Add custom bin
export PATH="/home/$HOME/bin:\$PATH"
EOF

# Add bbswitch to modprobe's loads
sudo tee /etc/modules-load.d/bbswitch.conf >/dev/null <<<'bbswitch'
# Replace first line of PostSession with #!/bin/bash
sudo sed -i "1s/.*/\#\!\/bin\/bash/" /etc/gdm3/PostSession/Default
# Add check to turn off GPU if intel GPU is selected on logoff
sudo tee /etc/gdm3/PostSession/Default >/dev/null <<EOF
if [[ "\$(prime-select query)" == "intel" ]]; then
  echo OFF >/proc/acpi/bbswitch
fi
EOF

# Transform home folders to lowercase
cp ./user-dirs.dirs ~/.config
cp ./bookmarks ~/.config/gtk-3.0
mv ~/Documents ~/documents
mv ~/Downloads ~/downloads
mv ~/Desktop ~/desktop
mv ~/Videos ~/videos
mv ~/Music ~/music
mv ~/Pictures ~/pictures
mv ~/Public ~/public
rmdir ~/Templates

# Configure git
if ! git config --global user.name > /dev/null 2>&1; then
  read -rp "git username: " git_username
  read -rp "git email: " git_email
  git config --global user.name "$git_username"
  git config --global user.email "$git_email"
  git config --global init.defaultBranch main
  git config --global core.editor vim # very important
fi

# Ask to instal dotfiles
echo "Basic setup done. Optionally, you can install dotfiles for zsh, vim, "
echo "Continue? (y/n)"
read -rp "" input
if [[ ! "$input" =~ ^[yY](es)?$ ]]; then
  echo "Done"
  exit 1
fi

echo "Please generate an ssh key by running these commands and add the public key to github via https://github.com/settings/keys:"
echo ""
echo "ssh-keygen -t rsa -b 4096 -C $(git config --global user.email) -f ~/.ssh/github -N"
echo 'eval "$(ssh-agent -s)"'
echo "ssh-add ~/.ssh/github"
echo ""

echo "Press enter to continue"

git clone git@github.com:Daves1245/dotfiles.git
dotfiles/install
