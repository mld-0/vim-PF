"	VIM SETTINGS: {{{3
"	VIM: let g:PF_filecmd_open_tagbar=0 g:PF_filecmd_NavHeadings="" g:PF_filecmd_NavSubHeadings="" g:PF_filecmd_NavDTS=0 g:PF_filecmd_vimgpgSave_gotoRecent=0
"	vim: set tabstop=4 modeline modelines=10 foldmethod=marker:
"	vim: set foldlevel=2 foldcolumn=3: 
"	}}}1
"	{{{2

let g:PF_loaded = 1
let s:PF_printdebug = 0

"	Get contents of mld_PF from env
let s:PF_path_dir = $mld_PF 
let s:PF_file_criterion = ".*\.txt"

let s:PF_prefix = "PF"

let s:PF_files_list = []
let s:PF_labels_list = []

let s:PF_putFile_flag_curloc_update = 1

let s:PF_curloc_update_do_zx = 1
let s:PF_curloc_update_do_zz = 1

let s:PF_curloc_unfoldall_on_save = 0
let s:PF_curloc_autoindent = ""
let s:PF_curloc_formatoptions = ""

let s:PF_curloc_ln = 1
let s:PF_curloc_fdl = 0

"	TODO: 2020-11-08T20:54:53AEDT Read filter regex / prefix from parameters file -> or list at top of script (is better than here)
function! g:PF_InitaliseAll()
	call g:PF_InitaliseCommands("(.*)\\.sh", "shell")
	call g:PF_InitaliseCommands("(.*)\\.py", "py")
	call g:PF_InitaliseCommands("(.*)\\.txt", "txt")
endfunction

"	Abort load (with warning) if s:PF_path_dir doesnt exist
"	{{{
if (!isdirectory(s:PF_path_dir))
	echo printf("warning, not found, PF_path_dir (env $mld_PF)\n\t%s", s:PF_path_dir)
endif
"	}}}

"	About: Return the name of the callee function
function! g:PF_CallerFuncName()
"	{{{
	let func_name = "PF_CallerFuncName"
	let func_printdebug = 0
	let result = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
	let result = substitute(result, '\S*\.\.\(\S*\)', '\1', '')
	"	{{{
	if (func_printdebug == 1)
		let message_str = printf("result=(%s)\n", result)
		echo message_str
	endif
	"	}}}
	return result
endfunction
"	}}}

function! g:PF_InitaliseCommands(arg_filter, arg_prefix)
"	{{{
	let func_name = g:PF_CallerFuncName()
	"	Get all files in directory s:PF_path_dir matching s:PF_file_criterion
	let _str_filter = a:arg_filter

	"	TODO: 2020-11-08T21:27:54AEDT remove/replace invalid characters for vim 'command!' declaration
	let _cmd_filter = printf(" | perl '-wne /%s/ and print' | perl -pe 's/%s/\\1/'", _str_filter, _str_filter)

	let _cmd_list = "ls -1 " . s:PF_path_dir . _cmd_filter

	let _cmd_filter = printf(" | perl '-wne /%s/ and print'", _str_filter)
	let _cmd_filenames = "ls -1 " . s:PF_path_dir . _cmd_filter

	let _result_list_str = trim(system(_cmd_list))
	let _result_list = split(_result_list_str, '\n')
	let _result_list_filenames_str = trim(system(_cmd_filenames))
	let _result_list_filenames  = split(_result_list_filenames_str, '\n')

	let _command_function = "g:PF_PutFile"

	"	Itterate over _result_list
	if (len(_result_list_filenames) != len(_result_list))
		echo printf("%s, mismatch, len(_result_list_filenames)=(%s), len(_result_list)=(%s)", func_name, len(_result_list_filenames), len(_result_list))
	endif

	"for loop_item in _result_list
	let i = 0
	while (i < len(_result_list))
		"	Ongoing: 2020-11-08T21:04:48AEDT Windows Paths (in vimscript?)
		let loop_name = _result_list[i]
		let loop_command_name = s:PF_prefix . a:arg_prefix . loop_name
		let loop_filepath = s:PF_path_dir . "/" .  _result_list_filenames[i]

		"	Continue: 2020-11-08T21:09:39AEDT Gimmie a file put into my buffer
		let loop_command = "command! " . loop_command_name . " call " . _command_function . "('" . loop_filepath . "')"
		"	Rules for <command> names?
		"	{{{
		if (s:PF_printdebug == 1)
			"echo i
			echo loop_command
			echo ""
		endif
		execute loop_command

		"	}}}
		let i += 1
	endwhile


	"	Create command for each item in PF_files_list
	let loop_i = 0
	while (loop_i < len(s:PF_files_list))
		let loop_i += 1
	endwhile

endfunction
"	}}}

function! g:PF_PutFile(path_file)
"	{{{
	let func_name = g:PF_CallerFuncName()
	let func_printdebug = 0
	let func_dryrun = 0
	let flag_curloc_update = s:PF_putFile_flag_curloc_update

	if (!filereadable(a:path_file))
		echo printf("%s, error, path_file=(%s) not readable\n", func_name, a:path_file)
		return 2
	endif

	"	Read lines of a:path_file to list:	
	let putfile_content = readfile(a:path_file)
	let putfile_content_len = len(putfile_content)

	"	{{{
	if (func_printdebug == 1)
		echo printf("putfile_content_len=(%s)\n", string(putfile_content_len))
	endif
	"	}}}

	"	Save current location
	let curloc_list = g:PF_CurLoc_Save()
	let temp_formatoptions = trim(execute("set formatoptions?"))
	exe "set noautoindent"

	exe "normal! O"

	"	Insert contents of file, line by line
	let loop_i = 0
	while (loop_i < putfile_content_len)
		let loop_putfile_line = putfile_content[loop_i]
		if (func_dryrun != 1)
			if (loop_i == 0)
				exe "normal! i" . loop_putfile_line
			else
				exe "normal! o" . loop_putfile_line
			endif

		endif
		let loop_i += 1
	endwhile

	"	Move cursor to saved position, then 
	if (flag_curloc_update == 1)
		silent call g:PF_CurLoc_Update(curloc_list)
		exe "set " . temp_formatoptions
	endif

	"	{{{
	if (func_printdebug == 1)
		echo printf("%s, path_file=(%s)\n", func_name, string(a:path_file))
	endif
	"	}}}

endfunction
"	}}}

"	Ongoing: 2020-11-08T16:53:16AEDT Taken from Mldvp, (known to) disable <autoindent>
function! g:PF_CurLoc_Save(...)
"	{{{
	let func_name = g:PF_CallerFuncName()
	let func_printdebug = 1
	let flag_restrict_format_options = get(a:, 1, 1)

	let s:PF_curloc_ln = line('.')
	let s:PF_curloc_fdl = &fdl

	"	Bugfix: (2020-07-27)-(2130-14) Mldvp, fix outputing of empty lines till end of screen on terminal when opening vim, culprit was use of "trim(execute('<cmd>'))" (see below)
	"let s:PF_curloc_autoindent = trim(execute("set autoindent?"))
	"let s:PF_curloc_formatoptions = trim(execute("set formatoptions?"))
	let s:PF_curloc_autoindent = "noautoindent" 
	if (&autoindent == 1)
		let s:PF_curloc_autoindent = "autoindent" 
	endif
	let s:PF_curloc_formatoptions = &formatoptions

	"	{{{
	if (func_printdebug == 1)
		echo printf("%s, ln=(%s), fdl=(%s), autoindent=(%s)\n", func_name, string(s:PF_curloc_ln), string(s:PF_curloc_fdl), string(s:PF_curloc_autoindent))
	endif
	"	}}}

	if (s:PF_curloc_unfoldall_on_save == 1)
		"	{{{
		if (func_printdebug == 1)
			echo printf("%s, unfold all\n", func_name)
		endif
		"	}}}
		execute "normal! zR"
	endif

	if (flag_restrict_format_options == 1)
		exe "set noautoindent"
		exe "set formatoptions=" . "ql"
	endif

	"return [ s:PF_curloc_ln, s:PF_curloc_fdl, s:PF_curloc_autoindent ]
	return [ s:PF_curloc_ln, s:PF_curloc_fdl, s:PF_curloc_autoindent , s:PF_curloc_formatoptions ]
endfunction
"	}}}

function! g:PF_CurLoc_Update(...)
"	{{{
	let func_name = g:PF_CallerFuncName()
	let func_printdebug = 1

	let curloc_restore_vals = get(a:, 1, [])
	let flag_require_args = 0

	let new_ln = str2nr(s:PF_curloc_ln)
	let new_fdl = str2nr(s:PF_curloc_fdl)
	let new_autoindent = s:PF_curloc_autoindent
	let new_formatoptions_cmd = s:PF_curloc_formatoptions
	if (len(curloc_restore_vals) > 0)
		let new_ln = str2nr(curloc_restore_vals[0])
		let new_fdl = str2nr(curloc_restore_vals[1])
		let new_autoindent = curloc_restore_vals[2]
		let new_formatoptions_cmd = curloc_restore_vals[3]
	else
		if (flag_require_args == 1)
			echo printf("%s, error, flag_rquire_args=(%s)\n", func_name, string(flag_require_args))
			return 2
		endif
	endif

	let cmd_ln_str = string(new_ln)
	"	{{{
	if (func_printdebug == 1)
		echo printf("%s, cmd_ln_str=(%s)\n", func_name, cmd_ln_str)
	endif
	"	}}}
	exe cmd_ln_str

	let cmd_fdl_str = "set fdl=" . string(new_fdl)
	"	{{{
	if (func_printdebug == 1)
		echo printf("%s, cmd_fdl_str=(%s)\n", func_name, cmd_fdl_str)
	endif
	"	}}}
	exe cmd_fdl_str

	let cmd_autoindent_str = "set " . new_autoindent
	"	{{{
	if (func_printdebug == 1)
		ech printf("%s, cmd_autoindent_str=(%s)\n", func_name, cmd_autoindent_str)
	endif
	"	}}}
	exe cmd_autoindent_str

	let cmd_formatoptions_str = "set formatoptions=" . new_formatoptions_cmd
	"	{{{
	if (func_printdebug == 1)
		ech printf("%s, cmd_formatoptions_str=(%s)\n", func_name, cmd_formatoptions_str)
	endif
	"	}}}
	exe cmd_formatoptions_str


	if (s:PF_curloc_update_do_zx == 1)
		exe "normal! zx"
	endif
	if (s:PF_curloc_update_do_zz == 1)
		exe "normal! zz" 
	endif

endfunction
"	}}}

"	}}}1

silent call g:PF_CurLoc_Save(0)
call g:PF_InitaliseAll()
