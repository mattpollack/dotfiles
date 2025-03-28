
if [ ! -d ~/.config/tmux ]; then
	cp .config/tmux ~/.config
else
	echo "> TMUX config exists"
fi

if [ ! -d ~/.config/nvim ]; then
	cp .config/nvim ~/.config
else
	echo "> NVIM config exists"
fi

if [ ! -d ~/.tmux/plugins/tpm ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
	echo "> TPM already installed"
fi

tmux source ~/.config/tmux/tmux.conf

