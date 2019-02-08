if exists('g:loaded_yaml-format') || &cp || !executable('yaml-format')
	finish
endif
let g:loaded_yaml_format = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:yaml_format_fmt_on_save")
	let g:yaml_format_fmt_on_save = 0
endif

if !exists('g:yaml_format_cmd')
	let g:yaml_format_cmd = 'align'
endif

" Options
if !exists('g:yaml_format_extra_args')
	let g:yaml_format_extra_args = ''
endif

" Ref: 'rhysd/vim-clang-format' /autoload/clang_format.vim
function! s:has_vimproc() abort
	if !exists('s:exists_vimproc')
		try
			silent call vimproc#version()
			let s:exists_vimproc = 1
		catch
			let s:exists_vimproc = 0
		endtry
	endif
	return s:exists_vimproc
endfunction
function! s:success(result) abort
	let exit_success = (s:has_vimproc() ? vimproc#get_last_status() : v:shell_error) == 0
	return exit_success
endfunction

function! s:error_message(result) abort
	echohl ErrorMsg
	echomsg 'yaml_format has failed to format.'
	echomsg ''
	echohl None
endfunction

let g:cnt = 0
function! s:yaml_format(current_args)
	let l:extra_args = g:yaml_format_extra_args
	let l:yaml_format_cmd = g:yaml_format_cmd
	let l:yaml_format_opts = ' ' . a:current_args . ' ' . l:extra_args
	if a:current_args != ''
		let l:yaml_format_opts = a:current_args
	endif
	let tempfilepath=tempname()
	call writefile(getline(1, '$'), tempfilepath)
	let l:yaml_format_output = system(l:yaml_format_cmd . ' ' . l:yaml_format_opts . ' ' . tempfilepath)
	if s:success(l:yaml_format_output)
		let pos_save = a:0 >= 1 ? a:1 : getpos('.')
		let winview = winsaveview()
		let splitted = readfile(tempfilepath)
		silent! undojoin
		if line('$') > len(splitted)
			execute len(splitted) .',$delete' '_'
		endif
		call setline(1, splitted)
		call winrestview(winview)
		call setpos('.', pos_save)
	else
		call s:error_message(l:yaml_format_output)
	endif
endfunction

augroup yaml_format
	autocmd!
	if get(g:, "yaml_format_fmt_on_save", 1)
		autocmd BufWritePre *.{yaml,yml} yaml_format
		autocmd FileType yaml autocmd BufWritePre <buffer> yaml_format
	endif
augroup END

command! -bar -nargs=? YAMLFormat :call <SID>yaml_format(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
