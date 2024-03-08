#!/bin/bash -x
user=$1
MYVIMRC="/home/$user/.vimrc"
VIMDIR="/home/$user/.vim"
mkdir -p $VIMDIR/plugged
#git clone https://github.com/hashivim/vim-terraform.git
#curl -fLo ~/.vim/autoload/plug.vim --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# additional plugins
cd $VIMDIR/plugged
git clone https://github.com/prabirshrestha/async.vim.git
git clone https://github.com/prabirshrestha/vim-lsp.git
git clone https://github.com/prabirshrestha/asyncomplete.vim.git
git clone https://github.com/prabirshrestha/asyncomplete-lsp.vim.git


# unzip
unzip -v
if [ $? -ne 0 ]; then
  apt install -y unzip
fi

# golang
go version
if [ $? -ne 0 ]; then
  apt install -y golang-go
fi

# nodejs
node -v
if [ $? -ne 0 ]; then
  cd /tmp
  curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
  bash nodesource_setup.sh
  apt install -y nodejs
fi

# vim language server
npm install -g vim-language-server

# terraform-ls
terraform-ls -v
if [ $? -ne 0 ]; then
  cd /tmp
  wget https://releases.hashicorp.com/terraform-ls/0.32.7/terraform-ls_0.32.7_linux_amd64.zip
  unzip terraform-ls_0.32.7_linux_amd64.zip
  mv terraform-ls /usr/bin/
fi

# terraform-lsp
terraform-lsp -v
if [ ! -f "/usr/bin/terraform-lsp" ]; then
  cd /tmp
  wget wget https://github.com/juliosueiras/terraform-lsp/releases/download/v0.0.11-beta2/terraform-lsp_0.0.11-beta2_linux_amd64.tar.gz
  tar zxvf terraform-lsp_0.0.11-beta2_linux_amd64.tar.gz
  mv terraform-lsp /usr/bin
fi



# vimrc
cat << EOF > /home/$user/.vimrc
set hlsearch
hi Search ctermbg=LightYellow
hi Search ctermfg=Red
set autoindent
set expandtab
set tabstop=2

if empty(glob('~/.vim/autoload/plug.vim'))
        silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
                \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

filetype plugin on
set omnifunc=syntaxcomplete#Complete

" Plugins will be downloaded under the specified directory.
call plug#begin('~/.vim/plugged')

" Declare the list of plugins.
"Plug 'joshdick/onedark.vim'
Plug 'hashivim/vim-terraform'
Plug 'vim-syntastic/syntastic'
Plug 'juliosueiras/vim-terraform-completion'
Plug 'neoclide/coc.nvim', {'branch': 'release'}


" List ends here. Plugins become visible to Vim after this call.
call plug#end()

if executable('terraform-ls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'terraform-ls',
        \ 'cmd': {server_info->['terraform-ls', 'serve']},
        \ 'whitelist': ['terraform'],
        \ })
endif

" Key bindings
" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
EOF

# coc-config.json
cat << EOF > $VIMDIR/coc-setting.json
{
        "languageserver": {
                "terraform": {
                        "command": "terraform-ls",
                        "args": ["serve"],
                        "filetypes": [
                                "terraform",
                                "tf"
                        ],
                        "initializationOptions": {},
                        "settings": {}
                }
        }
}
EOF


chown -R ${user}:${user} $VIMDIR $VIMRC
