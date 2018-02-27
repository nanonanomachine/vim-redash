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

command! -nargs=1 RedashDescribe call redash#describe(<f-args>)
command! -nargs=0 RedashExecute call redash#executeQuery()
command! -nargs=0 RedashPost call redash#postQuery()
command! -nargs=1 RedashSetDataSource call redash#setDataSource(<f-args>)
command! -nargs=0 RedashShowDataSources call redash#showDataSources()
command! -nargs=0 RedashShowTables call redash#showTables(<f-args>)
