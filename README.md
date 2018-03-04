# vim-redash

Manipulate [Redash](https://redash.io/) from vim.

This plugin tested with Redash 2.0.0+b2990.

# Installation

* Using [NeoBundle](https://github.com/Shougo/neobundle.vim), add these lines to your `.vimrc`

  ```
  NeoBundle 'nanonanomachine/vim-redash', {
  \ 'depends': ['mattn/webapi-vim']
  \}
  ```
 
* Using [Vundle](https://github.com/VundleVim/Vundle.vim), add these lines to your `.vimrc`

  ```
  Plugin 'mattn/webapi-vim'
  Plugin 'nanonanomachine/vim-redash'
  ```

# Getting started

1. Create `.redash.vim` in your home directroy.

        $ touch ~/.redash.vim

2. Edit `.redsah.vim` the following: 

        let g:redash_vim = {
        \ 'api_key':      'your_api_key',
        \ 'api_endpoint': 'your_api_endpoint',
        \}
  
  * `api_key` - Redash API Key. To get it, go to your account in Redash, the number in the URL just after /users/ is your User ID, i.e.  `{your_api_endpoint}/users/{user id}`. API key is also in your user settings, select the API KEY tab and copy it from there.
  
  * `api_endpoint` - Redash endpoint URL, e.g. `http://my_redash_endpoint.com`.

# Usage

1. Set DataSource by calling `:RedashSetDataSource  [data_source_id]`. You can show available DataSources by calling `:RedashShowDataSources`. Once you set a data source id it preserves so you don't need to set again.
2. Write some SQL. You can all `:RedashShowTables`  and `:RedashDescribe [table_name]` to get some usable information.
3. If you wanna post it as a new query, call `:RedashPost`. If you wanna just execute it and show result in vim, call `:RedashExecute`.

Example:

```vim
:RedashShowDataSources
=>
['1: Re:dash Metadata', '2: some_data_source', '3: another_data_source']
No DataSource set. You can call :RedashShowDataSources and :RedashSetDataSource command

:RedashSetDataSource 2

:RedashShowTables
=>
['some_table`, 'another_table']


:RedashDescribe some_table
=>
['some_column', 'another_column']

" Write some sql like SELECT some_column FROM some_table LIMIT 1;

:RedashPost
```

# Provided Commands

* `:RedashDescribe [table_name]` - Show columns of the table

* `:RedashExecute` - Execute query of current buffer and show the result in a new buffer

* `:RedashPost` - Post query of current buffer and show the result in browser

* `:RedashSetDataSource [data_source_id]` - Set DataSource. You must specify DataSource ID.

* `:RedashShowDataSources` - Show available DataSources. The leading numbers are DataSource Ids

* `:RedashShowTables` - Show table lists of current DataSource

# Demo

![example.gif](https://i.imgur.com/paNEufI.gif)

# Dependencies

* [mattn/webapi-vim](https://github.com/mattn/webapi-vim)
