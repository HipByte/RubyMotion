" These VIM rules match the MRI C indentation rules and Laurent's minimal VIM
" config rules.
"
" To enable use of this project specific config, add the following to your
" ~/.vimrc:
"
"   " Enable per-directory .vimrc files
"   set exrc
"   " Disable unsafe commands in local .vimrc files
"   set secure

function! MRIIndent()
  setlocal cindent
  setlocal noexpandtab
  setlocal shiftwidth=4
  setlocal softtabstop=4
  setlocal tabstop=8
  setlocal textwidth=80
  " Ensure function return types are not indented
  setlocal cinoptions=(0,t0
endfunction

autocmd Filetype c,cpp,objc call MRIIndent()
