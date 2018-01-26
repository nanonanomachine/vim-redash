let s:save_cpo = &cpo
set cpo&vim

function! redash#postQuery()
  if !exists('s:data_source_id')
    echo 'No DataSource set. You can call :RedashDatasources and :RedashSetSource command'
    return
  endif

  let l:query = join(getline(0, '$'), '\n')
  let l:data_source_id = 4

  let l:query_result = redash#apiPostQueryResult(l:query, l:data_source_id)
  if l:query_result[0] == v:null
    echo l:query_result[1]
    return
  endif

  let l:job = redash#apiGetJobId(l:query_result[0])
  if l:job[0] == v:null
    echo l:job[1]
    return
  endif

  let l:query = redash#apiPostQuery(l:query, l:data_source_id, l:job[0])
  if l:query[0] == v:null
    echo l:query[1]
    return
  endif

  " Open query result in Browswer
  call netrw#BrowseX(g:redash_vim['api_endpoint']."/queries/".query[0]."/source", netrw#CheckIfRemote())
endfunction

function! redash#apiGetDataSourceId()
  let l:res = webapi#http#get(g:redash_vim['api_endpoint']."/api/data_sources?api_key=".g:redash_vim['api_key'])
  echo map(webapi#json#decode(l:res.content), 'v:val["id"].": ".v:val["name"]')
  echo "Current DataSource Id: ".(exists("s:data_source_id") ? s:data_source_id : "Not set")
endfunction

function! redash#setDataSource(data_source_id)
  let s:data_source_id = a:data_source_id
endfunc

function! redash#apiPostQueryResult(query, data_source_id)
  let l:execute_query_body = { "query": a:query, "data_source_id": a:data_source_id }
  let l:execute_query_body.max_age = 0
  let query_result_res = webapi#http#post(
    \ g:redash_vim['api_endpoint']."/api/query_results?api_key=".g:redash_vim['api_key'],
    \ json_encode(l:execute_query_body)
    \ )
  if query_result_res.status !~ "^2.*"
    return [v:null, 'Failed to create query']
  endif
  return [webapi#json#decode(query_result_res.content)["job"]["id"], v:null]
endfunction

function! redash#apiGetJobId(job_id)
  while 1
    let l:job_res = webapi#http#get(g:redash_vim['api_endpoint']."/api/jobs/".a:job_id."?api_key=".g:redash_vim['api_key'])
    let l:job_res_content = webapi#json#decode(l:job_res.content)
    let l:status =  l:job_res_content["job"]["status"]
    let l:query_result_id  =  l:job_res_content["job"]["query_result_id"]

    if l:status == 3
      return [l:query_result_id, v:null]
    elseif status != 2
      return [v:null, l:job_res_content["job"]["error"]]
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
    return [v:null, 'Failed to create query']
  endif

  return [webapi#json#decode(l:query_res.content)["id"], v:null]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

