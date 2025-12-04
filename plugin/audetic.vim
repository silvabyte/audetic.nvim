" audetic.vim - Voice-triggered AI coding assistance
" Maintainer: silvabyte
" License: MIT

if exists('g:loaded_audetic')
  finish
endif
let g:loaded_audetic = 1

" Commands are created in lua/audetic/voice.lua setup()
" This file just prevents double-loading
