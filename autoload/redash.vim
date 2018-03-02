let s:save_cpo = &cpo
set cpo&vim

let s:data_source_file = $HOME.'/.redash-vim-data-source'
let s:V = vital#redash#new()
let s:TT = s:V.import('Text.Table')
let s:VT = s:V.import('Vim.ViewTracer')

function! redash#executeQuery()
  let l:data_source_id = s:get_data_source_id()
  if l:data_source_id == 0
    return
  endif

  let l:query = join(getline(1, '$'), "\n")

  let l:query_result_id = s:get_query_result_id(l:data_source_id, l:query)
  if l:query_result_id == 0
    return
  endif

  let l:query_result = redash#webapi#getQueryResult(l:query_result_id)
  if l:query_result['error'] != v:null
    echo l::uery_result['error']
    return
  endif

  let l:prev_window = s:VT.trace_window()

  lefta new
  let l:columns = keys(l:query_result['result']['data']['rows'][0])
  let l:table = s:TT.new({
  \ 'columns': map(copy(l:columns), '{}'),
  \ 'header': l:columns
  \})
  call l:table.rows(map(copy(l:query_result['result']['data']['rows']), 'values(v:val)'))
  call setline('$', l:table.stringify())
  call append('$', 'runtime: '.string(l:query_result['result']['runtime']).' sec')

  call s:VT.jump(prev_window)
  redraw
endfunction

function! redash#describe(table_name)
  let l:data_source_id = s:get_data_source_id()
  if l:data_source_id == 0
    return
  endif

  let l:schema = redash#webapi#getSchema(l:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  let l:table = filter(l:schema['result'], 'v:val["name"] == "'.a:table_name.'"')

  if len(l:table) == 0
    echo a:table_name.' does not exist'
    return
  endif

  echo a:table_name
  echo '--------------'
  echo l:table[0]['columns']
endfunction

function! redash#postQuery()
  let l:data_source_id = s:get_data_source_id()
  if l:data_source_id == 0
    return
  endif

  let l:query = join(getline(1, '$'), "\n")

  let l:query_result_id = s:get_query_result_id(l:data_source_id, l:query)
  if l:query_result_id == 0
    return
  endif

  let l:query = redash#webapi#postQuery(l:query, l:data_source_id, l:query_result_id)
  if l:query['error'] != v:null
    echo l:query['error']
    return
  endif

  " Open query result in Browswer
  call netrw#BrowseX(g:redash_vim['api_endpoint'].'/queries/'.l:query['result'].'/source', netrw#CheckIfRemote())
endfunction

function! redash#setDataSource(data_source_id)
  let s:data_source_id = a:data_source_id
  call writefile([s:data_source_id], s:data_source_file)
endfunction

function! redash#showDataSources()
  let l:data_sources = redash#webapi#getDataSources()
  if l:data_sources['error'] != v:null
    echo l:data_sources['error']
    return
  endif

  echo map(l:data_sources['result'], 'v:val["id"].": ".v:val["name"]')

  let l:data_source_id = s:get_data_source_id()
  if l:data_source_id == 0
    return
  endif

  echo 'Current DataSource Id: '.l:data_source_id
endfunction

function! redash#showTables()
  let l:data_source_id = s:get_data_source_id()
  if l:data_source_id == 0
    return
  endif

  let l:schema = redash#webapi#getSchema(s:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  echo map(l:schema['result'], 'v:val["name"]')
endfunction

function! s:get_data_source_id()
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

function! s:get_query_result_id(data_source_id, query)
  let l:query_result = redash#webapi#postQueryResult(a:query, a:data_source_id)
  if l:query_result['error'] != v:null
    echo l:query_result['error']
    return 0
  endif

  let l:job = redash#webapi#getJob(l:query_result['result'])
  if l:job['error'] != v:null
    echo l:job['error']
    return 0
  endif
  return l:job['result']['query_result_id']
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
