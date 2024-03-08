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
git clone https://github.com/jiangmiao/auto-pairs.git

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
hi MatchParen cterm=none ctermbg=yellow ctermfg=black

" Minimal Configuration
set nocompatible
syntax on
filetype plugin indent on


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

" Syntastic Config
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" (Optional)Remove Info(Preview) window
set completeopt-=preview

" (Optional)Hide Info(Preview) window after completions
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif

" (Optional) Enable terraform plan to be include in filter
let g:syntastic_terraform_tffilter_plan = 1

" (Optional) Default: 0, enable(1)/disable(0) plugin's keymapping
let g:terraform_completion_keys = 1

" (Optional) Default: 1, enable(1)/disable(0) terraform module registry completion
let g:terraform_registry_module_completion = 0


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
