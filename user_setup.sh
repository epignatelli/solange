# update packages
sudo apt update
sudo apt upgrade

# install required packages
apt install git
apt install wget

# git config
git config --global credential.helper store

# install oh-my-zsh
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# set oh-my-bash plugins and theme
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
sed -i "s/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" ~./zshrc
sed -i "s/ZSH_THEME=*\n/ZSH_THEME=af-magic\n/g" ~/.zshrc
