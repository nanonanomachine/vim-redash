let s:save_cpo = &cpo
set cpo&vim

let s:data_source_file = $HOME.'/.redash-vim-data-source'

function! redash#Describe(table_name)
  let l:data_source_id = s:getDataSourceId()
  if l:data_source_id == 0
    return
  endif

  let l:schema = redash#webapi#GetSchema(l:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  echo a:table_name
  echo '--------------'
  echo l:schema['result'][a:table_name]["columns"]
endfunction

function! redash#postQuery()
  let l:data_source_id = s:getDataSourceId()
  if l:data_source_id == 0
    return
  endif

  let l:query = join(getline(1, '$'), "\n")

  let l:query_result = redash#webapi#PostQueryResult(l:query, l:data_source_id)
  if l:query_result['error'] != v:null
    echo l:query_result['error']
    return
  endif

  let l:job = redash#webapi#GetJobId(l:query_result['result'])
  if l:job['error'] != v:null
    echo l:job['error']
    return
  endif

  let l:query = redash#webapi#PostQuery(l:query, l:data_source_id, l:job['result'])
  if l:query['error'] != v:null
    echo l:query['error']
    return
  endif

  " Open query result in Browswer
  call netrw#BrowseX(g:redash_vim['api_endpoint']."/queries/".l:query['result']."/source", netrw#CheckIfRemote())
endfunction

function! redash#setDataSource(data_source_id)
  let s:data_source_id = a:data_source_id
  call writefile([s:data_source_id], s:data_source_file)
endfunction

function! redash#showDataSources()
  let l:data_sources = redash#webapi#GetDataSources()
  if l:data_sources['error'] != v:null
    echo l:data_sources['error']
    return
  endif

  echo map(l:data_sources['result'], 'v:val["id"].": ".v:val["name"]')

  let l:data_source_id = s:getDataSourceId()
  if l:data_source_id == 0
    return
  endif

  echo "Current DataSource Id: ".l:data_source_id
endfunction

function! redash#showTables()
  let l:data_source_id = s:getDataSourceId()
  if l:data_source_id == 0
    return
  endif

  let l:schema = redash#webapi#GetSchema(s:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  echo map(l:schema['result'], 'v:val["name"]')
endfunction

function! s:getDataSourceId()
  if exists('s:data_source_id')
    if s:data_source_id == 0
      echo 'DataSource is invalid. You can call :RedashShowDataSources and :RedashSetDataSource command'
    endif

    return s:data_source_id
  endif

  if filereadable(s:data_source_file)
    let s:data_source_id = str2nr(join(readfile(s:data_source_file), ''))
    return s:data_source_id
  else
    echo 'No DataSource set. You can call :RedashShowDataSources and :RedashSetDataSource command'
    return 0
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
