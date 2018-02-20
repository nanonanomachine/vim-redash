let s:save_cpo = &cpo
set cpo&vim

let s:data_source_file = $HOME.'/.redash-vim-data-source'

function! redash#postQuery()
  if !exists('s:data_source_id')
    echo 'No DataSource set. You can call :RedashDatasources and :RedashSetSource command'
    return
  endif

  let l:query = join(getline(1, '$'), "\n")

  let l:query_result = redash#webapi#PostQueryResult(l:query, s:data_source_id)
  if l:query_result['error'] != v:null
    echo l:query_result['error']
    return
  endif

  let l:job = redash#webapi#GetJobId(l:query_result['result'])
  if l:job['error'] != v:null
    echo l:job['error']
    return
  endif

  let l:query = redash#webapi#PostQuery(l:query, s:data_source_id, l:job['result'])
  if l:query['error'] != v:null
    echo l:query['error']
    return
  endif

  " Open query result in Browswer
  call netrw#BrowseX(g:redash_vim['api_endpoint']."/queries/".l:query['result']."/source", netrw#CheckIfRemote())
endfunction

function! redash#getDataSources()
  let l:data_sources = redash#webapi#GetDataSources()
  if l:data_sources['error'] != v:null
    echo l:data_sources['error']
    return
  endif

  echo map(l:data_sources['result'], 'v:val["id"].": ".v:val["name"]')

  " Todo: It's great if we ask to set Id instead of just showing "Not set"
  echo "Current DataSource Id: ".(exists("s:data_source_id") ? s:data_source_id : "Not set")
endfunction

function! redash#setDataSource(data_source_id)
  let s:data_source_id = a:data_source_id
  call writefile([s:data_source_id], s:data_source_file)
endfunction

function! redash#showTables()
  if !exists('s:data_source_id')
    echo 'No DataSource set. You can call :RedashDatasources and :RedashSetSource command'
    return
  endif

  let l:schema = redash#webapi#GetSchema(s:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  echo map(l:schema['result'], 'v:val["name"]')
endfunction

function! redash#Describe(table_name)
  if !exists('s:data_source_id')
    echo 'No DataSource set. You can call :RedashDatasources and :RedashSetSource command'
    return
  endif

  let l:schema = redash#webapi#GetSchema(s:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  echo a:table_name
  echo '--------------'
  echo l:schema['result'][a:table_name]["columns"]
endfunction

function! redash#readDataSource()
  if filereadable(s:data_source_file)
    let s:data_source_id = join(readfile(s:data_source_file), '')
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
