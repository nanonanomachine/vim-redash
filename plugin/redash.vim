let s:config_file_exists = 1
try
  execute 'source $HOME/.redash.vim'
catch
  let s:config_file_exists = 0 " .redash.vim doesn't exist
endtry

if s:config_file_exists == 1
  source $HOME/.redash.vim
endif

if exists('g:loaded_vim_redash')
  finish
endif
let g:loaded_vim_redash = 1

" This script expects the following variables in ~/.redash.vim
" - g:redash_vim['api_key']        API Key
" - g:redash_vim['api_endpoint']   Endpoint of API

command! -nargs=0 RedashPost call redash#postQuery()
command! -nargs=0 RedashDataSources call redash#apiGetDataSourceId()
command! -nargs=1 RedashSetSource call redash#setDataSource(<f-args>)
