let s:save_cpo = &cpo
set cpo&vim

""""""""""""""""""""""""""""""""""""""""""
" Public API
""""""""""""""""""""""""""""""""""""""""""

function! redash#postQuery()
  if !exists('s:data_source_id')
    echo 'No DataSource set. You can call :RedashDatasources and :RedashSetSource command'
    return
  endif

  let l:query = join(getline(1, '$'), "\n")

  let l:query_result = redash#apiPostQueryResult(l:query, s:data_source_id)
  if l:query_result['error'] != v:null
    echo l:query_result['error']
    return
  endif

  let l:job = redash#apiGetJobId(l:query_result['result'])
  if l:job['error'] != v:null
    echo l:job['error']
    return
  endif

  let l:query = redash#apiPostQuery(l:query, s:data_source_id, l:job['result'])
  if l:query['error'] != v:null
    echo l:query['error']
    return
  endif

  " Open query result in Browswer
  call netrw#BrowseX(g:redash_vim['api_endpoint']."/queries/".l:query['result']."/source", netrw#CheckIfRemote())
endfunction

function! redash#getDataSources()
  let l:data_sources = redash#apiGetDataSources()
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
endfunction

function! redash#showTables(data_source_id)
  let l:schema = redash#apiGetSchema(a:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  echo map(l:schema['result'], 'v:val["name"]')
endfunction

function! redash#Describe(data_source_id, table_name)
  let l:schema = redash#apiGetSchema(a:data_source_id)
  if l:schema['error'] != v:null
    echo l:schema['error']
    return
  endif

  echo a:table_name
  echo '--------------'
  echo l:schema['result'][a:table_name]["columns"]
endfunction

""""""""""""""""""""""""""""""""""""""""""
" Private API
""""""""""""""""""""""""""""""""""""""""""

function! redash#apiGetDataSources()
  let l:res = webapi#http#get(g:redash_vim['api_endpoint']."/api/data_sources?api_key=".g:redash_vim['api_key'])

  if l:res.status !~ "^2.*"
    return { "result": v:null, "error": 'Failed to get data sources' }
  endif

  return { "result": webapi#json#decode(l:res.content), "error": v:null }
endfunction

function! redash#apiPostQueryResult(query, data_source_id)
  let l:execute_query_body = { "query": a:query, "data_source_id": a:data_source_id }
  let l:execute_query_body.max_age = 0
  let query_result_res = webapi#http#post(
    \ g:redash_vim['api_endpoint']."/api/query_results?api_key=".g:redash_vim['api_key'],
    \ json_encode(l:execute_query_body)
    \ )
  if query_result_res.status !~ "^2.*"
    return { "result": v:null, "error": 'Failed to create query' }
  endif
  return { "result": webapi#json#decode(query_result_res.content)["job"]["id"], "error": v:null }
endfunction

function! redash#apiGetJobId(job_id)
  while 1
    let l:job_res = webapi#http#get(g:redash_vim['api_endpoint']."/api/jobs/".a:job_id."?api_key=".g:redash_vim['api_key'])
    let l:job_res_content = webapi#json#decode(l:job_res.content)
    let l:status =  l:job_res_content["job"]["status"]
    let l:query_result_id  =  l:job_res_content["job"]["query_result_id"]

    if l:status == 3
      return { "result": l:query_result_id, "error": v:null }
    elseif status != 2
      return { "result": v:null, "error": l:job_res_content["job"]["error"] }
    endif

    sleep
  endwhile
endfunction

function! redash#apiPostQuery(query, data_source_id, query_result_id)
  let s:create_query_body = { "query": a:query, "data_source_id": a:data_source_id }
  let s:create_query_body.latest_query_data_id = a:query_result_id
  let s:create_query_body.schedule = v:null
  let s:create_query_body.name = "New Query"

  let l:query_res = webapi#http#post(
    \ g:redash_vim['api_endpoint']."/api/queries?api_key=".g:redash_vim['api_key'],
    \ json_encode(s:create_query_body)
    \ )
  if l:query_res.status !~ "^2.*"
    return { "result": v:null, "error": 'Failed to create query' }
  endif

  return { "result": webapi#json#decode(l:query_res.content)["id"], "error": v:null }
endfunction

function! redash#apiGetSchema(data_source_id)
  let l:schema_res = webapi#http#get(g:redash_vim['api_endpoint']."/api/data_sources/".a:data_source_id."/schema?api_key=".g:redash_vim['api_key'])
  if l:schema_res.status !~ "^2.*"
    return { "result": v:null, "error": 'Failed to get schema' }
  endif
  return { "result": webapi#json#decode(l:schema_res.content), "error": v:null }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
