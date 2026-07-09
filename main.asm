global _start

section .data
  locked_terminal db \
    27, "[?1049h", \
    27, "[2J", \
    27, "[H", \
    27, "[?25l"
  locked_terminal_length equ $ - locked_terminal

  free_terminal db 27, "[?1049l"
  free_terminal_length equ $ - free_terminal

  draw_buffer_x_size equ 112
  draw_buffer_y_size equ 24
  draw_buffer_size equ draw_buffer_x_size * draw_buffer_y_size

  clear_terminal db 27, "[2J"
  clear_terminal_length equ $ - clear_terminal

  cursor_start db 27, "[H"
  cursor_start_length equ $ - cursor_start

  new_line db 10
  enable_mouse db 27, "[?1000h"
  enable_mouse_length equ $ - enable_mouse

  disable_mouse db 27, "[?1000l"
  disable_mouse_length equ $ - disable_mouse

  max_number equ 1000000
  lifetime_ep_text db "Lifetime EP"
  lifetime_ep_text_len equ $ - lifetime_ep_text

  trash_text db "Trash"
  trash_text_len equ $ - trash_text

  common_text db "Common"
  common_text_len equ $ - common_text 
  
  uncommon_text db "Uncommon"
  uncommon_text_len equ $ - uncommon_text 
  
  rare_text db "Rare"
  rare_text_len equ $ - rare_text 
  
  anomaly_text db "Anomaly"
  anomaly_text_len equ $ - anomaly_text 
  
  legendary_text db "Legendary"
  legendary_text_len equ $ - legendary_text 
  
  absurd_text db "Absurd"
  absurd_text_len equ $ - absurd_text

  red_seq db 27, "[38;2;255;0;0m"
  red_len equ $ - red_seq

  white_seq db 27, "[38;2;255;255;255m"
  white_len equ $ - white_seq

  green_seq db 27, "[38;2;0;255;0m"
  green_len equ $ - green_seq

  light_blue_seq db 27, "[38;2;102;204;255m"
  light_blue_len equ $ - light_blue_seq

  purple_seq db 27, "[38;2;170;0;255m"
  purple_len equ $ - purple_seq

  blue_seq db 27, "[38;2;0;102;255m"
  blue_len equ $ - blue_seq

  lavender_seq db 27, "[38;2;230;200;255m"
  lavender_len equ $ - lavender_seq

  reset_color_seq db 27, "[0m"
  reset_color_len equ $ - reset_color_seq
  
  savefile db "rngdleasm", 0

  data_size equ data_end - data_start

section .bss
  terminal_input resb 1
  termios_orig resb 60
  termios_raw resb 60
  
  draw_buffer resb draw_buffer_size
  color_buffer resb draw_buffer_size

  mouse_down resb 1

data_start:
  numbers resb 6
  state resq 2

  lifetime_ep resq 1

  history resb (7 + 16) * 7
  history_index resb 1
  current resb 9
  attempts resq 1

  trash_numbers resq 1
  common_numbers resq 1
  uncommon_numbers resq 1
  rare_numbers resq 1
  anomaly_numbers resq 1
  legendary_numbers resq 1
  absurd_numbers resq 1
data_end:

section .text
_start:
  call main

  mov rax, 1
  mov rdi, 1
  mov rsi, free_terminal
  mov rdx, free_terminal_length
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, disable_mouse
  mov rdx, disable_mouse_length
  syscall

  call restore_terminal

  mov rax, 60
  xor rdi, rdi

  syscall

set_raw_mode:
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5401
    mov rdx, termios_orig
    syscall

    lea rsi, [termios_orig]
    lea rdi, [termios_raw]
    mov rcx, 60
    rep movsb

    mov eax, [termios_raw + 12]
    and eax, ~(0x2 | 0x8)
    mov [termios_raw + 12], eax

    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402
    mov rdx, termios_raw
    syscall

    ret

restore_terminal:
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402
    mov rdx, termios_orig
    syscall
    ret

get_char:
    mov rax, 0
    mov rdi, 0
    mov rsi, terminal_input
    mov rdx, 1
    syscall
    ret

get_index:
    mov rdx, rdi
    imul rdx, draw_buffer_x_size
    add rdx, rax
    ret
    
get_history_index:
  mov rdx, 7 + 16
  imul rdx, rax
  ret

shift_history:
    mov r8, 0

shift_loop:
    cmp r8, 6
    jge done

    mov rax, r8
    call get_history_index
    mov r9, rdx

    mov rax, r8
    inc rax
    call get_history_index

    lea rdi, [history + r9]
    lea rsi, [history + rdx]
    mov rcx, 23
    rep movsb

    inc r8
    jmp shift_loop

done:
    ret

draw:
  mov rsi, 0

  mov rdi, draw_buffer
  mov rcx, draw_buffer_size
  mov al, ' '
  rep stosb

  mov rdi, color_buffer
  mov rcx, draw_buffer_size
  mov al, 0
  rep stosb

  mov r10b, [current + 8]
  mov rdi, 1
  mov rax, (draw_buffer_x_size / 2) - (5 * 6)
  call get_index
  mov byte [color_buffer + rdx], r10b

  x_loop:
      cmp rsi, 6
      je x_loop_end
      
      push rax

      draw_x_loop:
          mov rdi, 1
          call get_index
          mov byte [draw_buffer + rdx], '+'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '+'

          pop rax
          push rax

          mov rdi, 3
          call get_index
          mov byte [draw_buffer + rdx], '+'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '-'
          add rax, 1
          call get_index
          mov byte [draw_buffer + rdx], '+'

          pop rax
          mov rdi, 2

          call get_index
          mov byte [draw_buffer + rdx], '|'

          add rax, 3
          call get_index

          mov cl, [numbers + rsi]
          add cl, 48
          mov byte [draw_buffer + rdx], cl

          add rax, 3
          call get_index
          mov byte [draw_buffer + rdx], '|'

          add rax, 4
          inc rsi
          jmp x_loop
      x_loop_end:

      inc rax
      inc rdi
      call get_index
      mov byte [color_buffer + rdx], '?'

      cmp byte [mouse_down], 1
      je draw_button_pressed
      jmp draw_button_unpressed

      draw_button_pressed:

      mov rax, (draw_buffer_x_size / 2) - 13
      mov rdi, 12
      call get_index
      mov byte [draw_buffer + rdx], '*'

      mov rsi, 0
      button_loop_x_pressed:
        cmp rsi, 22
        jg button_loop_x_pressed_end
        inc rax
        mov rdi, 12
        call get_index
        mov byte [draw_buffer + rdx], '~'
        mov rdi, 14
        call get_index
        mov byte [draw_buffer + rdx], '~'
        inc rsi
        jmp button_loop_x_pressed
      button_loop_x_pressed_end:

      mov rax, (draw_buffer_x_size / 2) - 13
      mov rdi, 14
      call get_index
      mov byte [draw_buffer + rdx], '*'

      mov rax, (draw_buffer_x_size / 2) - 13
      add rax, 23
      mov rdi, 12
      call get_index
      mov byte [draw_buffer + rdx], '*'

      mov rdi, 14
      call get_index
      mov byte [draw_buffer + rdx], '*'

      mov rax, (draw_buffer_x_size / 2) - 13
      mov rdi, 13
      call get_index
      mov byte [draw_buffer + rdx], '|'

      mov rax, (draw_buffer_x_size / 2) - 13
      add rax, 23
      mov rdi, 13
      call get_index
      mov byte [draw_buffer + rdx], '|'
      jmp draw_button_text

      draw_button_unpressed:

      mov rax, (draw_buffer_x_size / 2) - 13
      mov rdi, 12
      call get_index
      mov byte [draw_buffer + rdx], '+'

      mov rsi, 0
      button_loop_x_unpressed:
        cmp rsi, 22
        jg button_loop_x_unpressed_end
        inc rax
        mov rdi, 12
        call get_index
        mov byte [draw_buffer + rdx], '-'
        mov rdi, 14
        call get_index
        mov byte [draw_buffer + rdx], '-'
        inc rsi
        jmp button_loop_x_unpressed
      button_loop_x_unpressed_end:

      mov rax, (draw_buffer_x_size / 2) - 13
      mov rdi, 14
      call get_index
      mov byte [draw_buffer + rdx], '+'

      mov rax, (draw_buffer_x_size / 2) - 13
      add rax, 23
      mov rdi, 12
      call get_index
      mov byte [draw_buffer + rdx], '+'

      mov rdi, 14
      call get_index
      mov byte [draw_buffer + rdx], '+'

      mov rax, (draw_buffer_x_size / 2) - 13
      mov rdi, 13
      call get_index
      mov byte [draw_buffer + rdx], '|'

      mov rax, (draw_buffer_x_size / 2) - 13
      add rax, 23
      mov rdi, 13
      call get_index
      mov byte [draw_buffer + rdx], '|'
      jmp draw_button_text
  
draw_button_text:
  mov rax, (draw_buffer_x_size / 2) - 13
  add rax, 9
  mov rdi, 13
  call get_index
  mov byte [draw_buffer + rdx], 'R'
  add rax, 1
  call get_index
  mov byte [draw_buffer + rdx], 'E'
  add rax, 1
  call get_index
  mov byte [draw_buffer + rdx], 'R'
  add rax, 1
  call get_index
  mov byte [draw_buffer + rdx], 'O'
  add rax, 1
  call get_index
  mov byte [draw_buffer + rdx], 'L'
  add rax, 1
  call get_index
  mov byte [draw_buffer + rdx], 'L'

  ; ATTEMPT - 7
  mov r14, [attempts]
  mov r13, 0
  attempts_digit_loop:
    cmp r14, 0
    jle attempts_digit_loop_end
    mov rax, r14
    mov rcx, 10
    xor rdx, rdx
    div rcx
    push rdx
    mov r14, rax
    inc r13
    jmp attempts_digit_loop
  attempts_digit_loop_end:

  mov rax, (draw_buffer_x_size / 2) - 5
  mov r14, r13
  shr r14, 1
  sub rax, r14
  mov rdi, 16
  call get_index

  mov byte [draw_buffer + rdx], 'A'
  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'T'
  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'T'
  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'E'
  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'M'
  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'P'
  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'T'
  inc rax
  call get_index
  mov byte [draw_buffer + rdx], ':'

  add rax, 2

  mov r15, 0
  attempts_digit_draw_loop:
    cmp r15, r13
    jge attempts_digit_draw_loop_end
    
    call get_index
    pop rcx
    add rcx, 48
    mov byte [draw_buffer + rdx], cl
    inc r15
    inc rax
    jmp attempts_digit_draw_loop
  attempts_digit_draw_loop_end:
  
  mov r14, [lifetime_ep]
  mov r13, 0
  ep_digit_loop:
    cmp r14, 0
    jle ep_digit_loop_end
    mov rax, r14
    mov rcx, 10
    xor rdx, rdx
    div rcx
    push rdx
    mov r14, rax
    inc r13
    jmp ep_digit_loop
  ep_digit_loop_end:

  mov r15, 0
  ep_digit_draw_loop:
    cmp r15, r13
    jge ep_digit_draw_loop_end
    mov rax, (draw_buffer_x_size / 2)
    mov r14, r13
    shr r14, 1
    sub rax, r14
    mov r14, (lifetime_ep_text_len / 2)
    sub rax, r14
    sub rax, 2
    add rax, r15
    mov rdi, 6
    call get_index
    pop rcx
    add rcx, 48
    mov byte [draw_buffer + rdx], cl
    inc r15
    jmp ep_digit_draw_loop
  ep_digit_draw_loop_end:

  add rax, 2
  mov r14, 0
  lifetime_ep_text_loop:
    cmp r14, lifetime_ep_text_len
    jge lifetime_ep_text_loop_end

    call get_index
    mov cl, [lifetime_ep_text + r14]
    mov byte [draw_buffer + rdx], cl

    inc r14
    inc rax
    jmp lifetime_ep_text_loop
  lifetime_ep_text_loop_end:

  movzx rcx, byte [current + 8]
  ; TRASH - 5
  ; COMMON - 6
  ; UNCOMMON - 8
  ; RARE - 4
  ; ANOMALY - 7
  ; LEGENDARY - 9
  ; ABSURD - 6

  cmp rcx, 1
  mov rbp, trash_text_len
  cmove rsi, rbp

  cmp rcx, 2
  mov rbp, common_text_len
  cmove rsi, rbp

  cmp rcx, 3
  mov rbp, uncommon_text_len
  cmove rsi, rbp

  cmp rcx, 4
  mov rbp, rare_text_len
  cmove rsi, rbp

  cmp rcx, 5
  mov rbp, anomaly_text_len
  cmove rsi, rbp

  cmp rcx, 6
  mov rbp, legendary_text_len
  cmove rsi, rbp
  
  cmp rcx, 7
  mov rbp, absurd_text_len
  cmove rsi, rbp

  mov r14, [current]
  mov r13, 0
  current_extract_loop:
    cmp r14, 0
    jle current_extract_loop_end

    mov rax, r14
    mov rcx, 10
    xor rdx, rdx
    div rcx
    push rdx
    mov r14, rax
    inc r13

    jmp current_extract_loop
  current_extract_loop_end:

  mov r15, 0
  mov rax, (draw_buffer_x_size / 2)
  mov r14, r13
  shr r14, 1
  sub rax, r14

  mov r14, rsi
  shr r14, 1
  sub rax, r14

  sub rax, 4
  mov rdi, 8
  
  call get_index
  mov r10b, [current + 8]
  mov byte [color_buffer + rdx], r10b

  current_draw_loop:
    cmp r15, r13
    jge current_draw_loop_end
    
    call get_index
    pop r14
    add r14, 48
    mov byte [draw_buffer + rdx], r14b

    inc rax
    inc r15
    jmp current_draw_loop
  current_draw_loop_end:

  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'E'

  inc rax
  call get_index
  mov byte [draw_buffer + rdx], 'P'

  add rax, 2
  call get_index
  mov byte [draw_buffer + rdx], '-'

  add rax, 2
  call get_index
  
  movzx rcx, byte [current + 8]
  mov r15, 0
  cmp rcx, 1
  je draw_trash_text
  
  cmp rcx, 2
  je draw_common_text

  cmp rcx, 3
  je draw_uncommon_text

  cmp rcx, 4
  je draw_rare_text

  cmp rcx, 5
  je draw_anomaly_text

  cmp rcx, 6
  je draw_legendary_text

  cmp rcx, 7
  je draw_absurd_text

  jmp draw_text_end

  draw_trash_text:
    cmp r15, trash_text_len
    jge draw_text_end

    mov r14b, [trash_text + r15]
    call get_index
    mov byte [draw_buffer + rdx], r14b

    inc rax
    inc r15
    jmp draw_trash_text

  draw_common_text:
    cmp r15, common_text_len
    jge draw_text_end

    mov r14b, [common_text + r15]
    call get_index
    mov byte [draw_buffer + rdx], r14b
    
    inc rax
    inc r15
    jmp draw_common_text

  draw_uncommon_text:
    cmp r15, uncommon_text_len
    jge draw_text_end

    mov r14b, [uncommon_text + r15]
    call get_index
    mov byte [draw_buffer + rdx], r14b
    
    inc rax
    inc r15
    jmp draw_uncommon_text

  draw_rare_text:
    cmp r15, rare_text_len
    jge draw_text_end

    mov r14b, [rare_text + r15]
    call get_index
    mov byte [draw_buffer + rdx], r14b
    
    inc rax
    inc r15
    jmp draw_rare_text

  draw_anomaly_text:
    cmp r15, anomaly_text_len
    jge draw_text_end

    mov r14b, [anomaly_text + r15]
    call get_index
    mov byte [draw_buffer + rdx], r14b
    
    inc rax
    inc r15
    jmp draw_anomaly_text

  draw_legendary_text:
    cmp r15, legendary_text_len
    jge draw_text_end

    mov r14b, [legendary_text + r15]
    call get_index
    mov byte [draw_buffer + rdx], r14b
    
    inc rax
    inc r15
    jmp draw_legendary_text

  draw_absurd_text:
    cmp r15, absurd_text_len
    jge draw_text_end

    mov r14b, [absurd_text + r15]
    call get_index
    mov byte [draw_buffer + rdx], r14b
    
    inc rax
    inc r15
    jmp draw_absurd_text
  draw_text_end:

  inc rax
  call get_index
  mov byte [color_buffer + rdx], '?'

  ; history resb (7 + 16) * 7

  mov rax, 0
  mov rdi, 5

  mov r14, 0
  draw_history_loop:
    cmp r14, 7
    jge draw_history_loop_end
    
    mov rax, r14
    call get_history_index
    mov r13, rdx
    add rdx, 6
    cmp byte [history + rdx], 0
    mov rdx, r13
    jne continue_draw_history_loop
    inc r14
    jmp draw_history_loop
    continue_draw_history_loop:

    mov rax, 0
    mov rdi, r14
    add rdi, 7
    call get_index

    mov r10, rdx

    mov rax, r14
    call get_history_index
    add rdx, 6
    mov r15b, [history + rdx]
    mov byte [color_buffer + r10], r15b

    mov rax, 0
    mov rdx, r10

    mov byte [draw_buffer + rdx], 'R'
    inc rax
    call get_index
    mov byte [draw_buffer + rdx], 'o'
    inc rax
    call get_index
    mov byte [draw_buffer + rdx], 'l'
    inc rax
    call get_index
    mov byte [draw_buffer + rdx], 'l'

    add rax, 2
    mov rsi, rax
    call get_index

    mov r8, r13
    add r8, 7
    mov r9, [history + r8]
    mov r10, 0
    history_roll_digit_loop:
      cmp r9, 0
      jle history_roll_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp history_roll_digit_loop
    history_roll_digit_loop_end:
    
    mov rax, rsi
    mov r15, 0
    history_roll_digit_draw_loop:
      cmp r15, r10
      jge history_roll_digit_draw_loop_end
      
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp history_roll_digit_draw_loop
    history_roll_digit_draw_loop_end:

    call get_index
    mov byte [draw_buffer + rdx], ':'

    add rax, 2
    call get_index

    xor r15, r15
    mov r15b, [history + r13]
    add r15b, 48
    mov byte [draw_buffer + rdx], r15b

    inc rax
    call get_index
    inc r13
    xor r15, r15
    mov r15b, [history + r13]
    add r15, 48
    mov byte [draw_buffer + rdx], r15b

    inc rax
    call get_index
    inc r13
    xor r15, r15
    mov r15b, [history + r13]
    add r15, 48
    mov byte [draw_buffer + rdx], r15b

    inc rax
    call get_index
    inc r13
    xor r15, r15
    mov r15b, [history + r13]
    add r15, 48
    mov byte [draw_buffer + rdx], r15b

    inc rax
    call get_index
    inc r13
    xor r15, r15
    mov r15b, [history + r13]
    add r15, 48
    mov byte [draw_buffer + rdx], r15b

    inc rax
    call get_index
    inc r13
    xor r15, r15
    mov r15b, [history + r13]
    add r15, 48
    mov byte [draw_buffer + rdx], r15b

    add rax, 2
    call get_index
    mov byte [draw_buffer + rdx], '-'

    add rax, 2
    mov rsi, rax
    call get_index

    add r8, 8
    mov r9, [history + r8]
    mov r10, 0
    history_ep_digit_loop:
      cmp r9, 0
      jle history_ep_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp history_ep_digit_loop
    history_ep_digit_loop_end:
    
    mov rax, rsi
    mov r15, 0
    history_ep_digit_draw_loop:
      cmp r15, r10
      jge history_ep_digit_draw_loop_end
      
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp history_ep_digit_draw_loop
    history_ep_digit_draw_loop_end:

    inc rax
    call get_index
    mov byte [draw_buffer + rdx], 'E'
    inc rax
    call get_index
    mov byte [draw_buffer + rdx], 'P'
    inc rax
    call get_index
    mov byte [color_buffer + rdx], '?'

    inc r14
    jmp draw_history_loop
  draw_history_loop_end:

  mov r8, [trash_numbers]
  add r8, [common_numbers]
  add r8, [uncommon_numbers]
  add r8, [rare_numbers]
  add r8, [anomaly_numbers]
  add r8, [legendary_numbers]
  add r8, [absurd_numbers]

  cmp [trash_numbers], 0
  jne draw_trash_numbers

  dtn_end:

  cmp [common_numbers], 0
  jne draw_common_numbers

  dcn_end:

  cmp [uncommon_numbers], 0
  jne draw_uncommon_numbers

  ducn_end:

  cmp [rare_numbers], 0
  jne draw_rare_numbers

  drn_end:

  cmp [anomaly_numbers], 0
  jne draw_anomaly_numbers

  dan_end:

  cmp [legendary_numbers], 0
  jne draw_legendary_numbers

  dln_end:

  cmp [absurd_numbers], 0
  jne draw_absurd_numbers

  jmp draw_numbers_end

  draw_trash_numbers:
      mov rax, (draw_buffer_x_size - 24)
      mov rdi, 7
      call get_index
      mov byte [color_buffer + rdx], 1
      mov rsi, rax
      mov r9, [trash_numbers]
      mov r10, 0
  trash_digit_loop:
      cmp r9, 0
      jne trash_digit_loop_nonzero
      push 0
      inc r10
      jmp trash_digit_loop_end
  trash_digit_loop_nonzero:
      cmp r9, 0
      jle trash_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp trash_digit_loop_nonzero
  trash_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  trash_digit_draw_loop:
      cmp r15, r10
      jge trash_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp trash_digit_draw_loop
  trash_digit_draw_loop_end:
      inc rax
      call get_index
      mov byte [draw_buffer + rdx], '-'
      add rax, 2
      mov rsi, rax
      mov rcx, r8
      mov rax, [trash_numbers]
      imul rax, 100
      xor rdx, rdx
      div rcx
      mov r9, rax
      mov rax, rsi
      mov r10, 0
  trash_percent_digit_loop:
      cmp r9, 0
      jne trash_percent_digit_loop_nonzero
      push 0
      inc r10
      jmp trash_percent_digit_loop_end
  trash_percent_digit_loop_nonzero:
      cmp r9, 0
      jle trash_percent_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp trash_percent_digit_loop_nonzero
  trash_percent_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  trash_percent_digit_draw_loop:
      cmp r15, r10
      jge trash_percent_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp trash_percent_digit_draw_loop
  trash_percent_digit_draw_loop_end:
      call get_index
      mov byte [draw_buffer + rdx], '%'
      inc rax
      call get_index
      mov byte [color_buffer + rdx], '?'
      jmp dtn_end
  
  draw_common_numbers:
      mov rax, (draw_buffer_x_size - 24)
      mov rdi, 8
      call get_index
      mov byte [color_buffer + rdx], 2
      mov rsi, rax
      mov r9, [common_numbers]
      mov r10, 0
  common_digit_loop:
      cmp r9, 0
      jne common_digit_loop_nonzero
      push 0
      inc r10
      jmp common_digit_loop_end
  common_digit_loop_nonzero:
      cmp r9, 0
      jle common_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp common_digit_loop_nonzero
  common_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  common_digit_draw_loop:
      cmp r15, r10
      jge common_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp common_digit_draw_loop
  common_digit_draw_loop_end:
      inc rax
      call get_index
      mov byte [draw_buffer + rdx], '-'
      add rax, 2
      mov rsi, rax
      mov rcx, r8
      mov rax, [common_numbers]
      imul rax, 100
      xor rdx, rdx
      div rcx
      mov r9, rax
      mov rax, rsi
      mov r10, 0
  common_percent_digit_loop:
      cmp r9, 0
      jne common_percent_digit_loop_nonzero
      push 0
      inc r10
      jmp common_percent_digit_loop_end
  common_percent_digit_loop_nonzero:
      cmp r9, 0
      jle common_percent_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp common_percent_digit_loop_nonzero
  common_percent_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  common_percent_digit_draw_loop:
      cmp r15, r10
      jge common_percent_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp common_percent_digit_draw_loop
  common_percent_digit_draw_loop_end:
      call get_index
      mov byte [draw_buffer + rdx], '%'
      inc rax
      call get_index
      mov byte [color_buffer + rdx], '?'
      jmp dcn_end
  
  draw_uncommon_numbers:
      mov rax, (draw_buffer_x_size - 24)
      mov rdi, 9
      call get_index
      mov byte [color_buffer + rdx], 3
      mov rsi, rax
      mov r9, [uncommon_numbers]
      mov r10, 0
  uncommon_digit_loop:
      cmp r9, 0
      jne uncommon_digit_loop_nonzero
      push 0
      inc r10
      jmp uncommon_digit_loop_end
  uncommon_digit_loop_nonzero:
      cmp r9, 0
      jle uncommon_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp uncommon_digit_loop_nonzero
  uncommon_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  uncommon_digit_draw_loop:
      cmp r15, r10
      jge uncommon_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp uncommon_digit_draw_loop
  uncommon_digit_draw_loop_end:
      inc rax
      call get_index
      mov byte [draw_buffer + rdx], '-'
      add rax, 2
      mov rsi, rax
      mov rcx, r8
      mov rax, [uncommon_numbers]
      imul rax, 100
      xor rdx, rdx
      div rcx
      mov r9, rax
      mov rax, rsi
      mov r10, 0
  uncommon_percent_digit_loop:
      cmp r9, 0
      jne uncommon_percent_digit_loop_nonzero
      push 0
      inc r10
      jmp uncommon_percent_digit_loop_end
  uncommon_percent_digit_loop_nonzero:
      cmp r9, 0
      jle uncommon_percent_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp uncommon_percent_digit_loop_nonzero
  uncommon_percent_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  uncommon_percent_digit_draw_loop:
      cmp r15, r10
      jge uncommon_percent_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp uncommon_percent_digit_draw_loop
  uncommon_percent_digit_draw_loop_end:
      call get_index
      mov byte [draw_buffer + rdx], '%'
      inc rax
      call get_index
      mov byte [color_buffer + rdx], '?'
      jmp ducn_end
  
  draw_rare_numbers:
      mov rax, (draw_buffer_x_size - 24)
      mov rdi, 10
      call get_index
      mov byte [color_buffer + rdx], 4
      mov rsi, rax
      mov r9, [rare_numbers]
      mov r10, 0
  rare_digit_loop:
      cmp r9, 0
      jne rare_digit_loop_nonzero
      push 0
      inc r10
      jmp rare_digit_loop_end
  rare_digit_loop_nonzero:
      cmp r9, 0
      jle rare_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp rare_digit_loop_nonzero
  rare_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  rare_digit_draw_loop:
      cmp r15, r10
      jge rare_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp rare_digit_draw_loop
  rare_digit_draw_loop_end:
      inc rax
      call get_index
      mov byte [draw_buffer + rdx], '-'
      add rax, 2
      mov rsi, rax
      mov rcx, r8
      mov rax, [rare_numbers]
      imul rax, 100
      xor rdx, rdx
      div rcx
      mov r9, rax
      mov rax, rsi
      mov r10, 0
  rare_percent_digit_loop:
      cmp r9, 0
      jne rare_percent_digit_loop_nonzero
      push 0
      inc r10
      jmp rare_percent_digit_loop_end
  rare_percent_digit_loop_nonzero:
      cmp r9, 0
      jle rare_percent_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp rare_percent_digit_loop_nonzero
  rare_percent_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  rare_percent_digit_draw_loop:
      cmp r15, r10
      jge rare_percent_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp rare_percent_digit_draw_loop
  rare_percent_digit_draw_loop_end:
      call get_index
      mov byte [draw_buffer + rdx], '%'
      inc rax
      call get_index
      mov byte [color_buffer + rdx], '?'
      jmp drn_end
  
  draw_anomaly_numbers:
      mov rax, (draw_buffer_x_size - 24)
      mov rdi, 11
      call get_index
      mov byte [color_buffer + rdx], 5
      mov rsi, rax
      mov r9, [anomaly_numbers]
      mov r10, 0
  anomaly_digit_loop:
      cmp r9, 0
      jne anomaly_digit_loop_nonzero
      push 0
      inc r10
      jmp anomaly_digit_loop_end
  anomaly_digit_loop_nonzero:
      cmp r9, 0
      jle anomaly_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp anomaly_digit_loop_nonzero
  anomaly_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  anomaly_digit_draw_loop:
      cmp r15, r10
      jge anomaly_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp anomaly_digit_draw_loop
  anomaly_digit_draw_loop_end:
      inc rax
      call get_index
      mov byte [draw_buffer + rdx], '-'
      add rax, 2
      mov rsi, rax
      mov rcx, r8
      mov rax, [anomaly_numbers]
      imul rax, 100
      xor rdx, rdx
      div rcx
      mov r9, rax
      mov rax, rsi
      mov r10, 0
  anomaly_percent_digit_loop:
      cmp r9, 0
      jne anomaly_percent_digit_loop_nonzero
      push 0
      inc r10
      jmp anomaly_percent_digit_loop_end
  anomaly_percent_digit_loop_nonzero:
      cmp r9, 0
      jle anomaly_percent_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp anomaly_percent_digit_loop_nonzero
  anomaly_percent_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  anomaly_percent_digit_draw_loop:
      cmp r15, r10
      jge anomaly_percent_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp anomaly_percent_digit_draw_loop
  anomaly_percent_digit_draw_loop_end:
      call get_index
      mov byte [draw_buffer + rdx], '%'
      inc rax
      call get_index
      mov byte [color_buffer + rdx], '?'
      jmp dan_end
  
  draw_legendary_numbers:
      mov rax, (draw_buffer_x_size - 24)
      mov rdi, 12
      call get_index
      mov byte [color_buffer + rdx], 6
      mov rsi, rax
      mov r9, [legendary_numbers]
      mov r10, 0
  legendary_digit_loop:
      cmp r9, 0
      jne legendary_digit_loop_nonzero
      push 0
      inc r10
      jmp legendary_digit_loop_end
  legendary_digit_loop_nonzero:
      cmp r9, 0
      jle legendary_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp legendary_digit_loop_nonzero
  legendary_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  legendary_digit_draw_loop:
      cmp r15, r10
      jge legendary_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp legendary_digit_draw_loop
  legendary_digit_draw_loop_end:
      inc rax
      call get_index
      mov byte [draw_buffer + rdx], '-'
      add rax, 2
      mov rsi, rax
      mov rcx, r8
      mov rax, [legendary_numbers]
      imul rax, 100
      xor rdx, rdx
      div rcx
      mov r9, rax
      mov rax, rsi
      mov r10, 0
  legendary_percent_digit_loop:
      cmp r9, 0
      jne legendary_percent_digit_loop_nonzero
      push 0
      inc r10
      jmp legendary_percent_digit_loop_end
  legendary_percent_digit_loop_nonzero:
      cmp r9, 0
      jle legendary_percent_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp legendary_percent_digit_loop_nonzero
  legendary_percent_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  legendary_percent_digit_draw_loop:
      cmp r15, r10
      jge legendary_percent_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp legendary_percent_digit_draw_loop
  legendary_percent_digit_draw_loop_end:
      call get_index
      mov byte [draw_buffer + rdx], '%'
      inc rax
      call get_index
      mov byte [color_buffer + rdx], '?'
      jmp dln_end
  
  draw_absurd_numbers:
      mov rax, (draw_buffer_x_size - 24)
      mov rdi, 13
      call get_index
      mov byte [color_buffer + rdx], 7
      mov rsi, rax
      mov r9, [absurd_numbers]
      mov r10, 0
  absurd_digit_loop:
      cmp r9, 0
      jne absurd_digit_loop_nonzero
      push 0
      inc r10
      jmp absurd_digit_loop_end
  absurd_digit_loop_nonzero:
      cmp r9, 0
      jle absurd_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp absurd_digit_loop_nonzero
  absurd_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  absurd_digit_draw_loop:
      cmp r15, r10
      jge absurd_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp absurd_digit_draw_loop
  absurd_digit_draw_loop_end:
      inc rax
      call get_index
      mov byte [draw_buffer + rdx], '-'
      add rax, 2
      mov rsi, rax
      mov rcx, r8
      mov rax, [absurd_numbers]
      imul rax, 100
      xor rdx, rdx
      div rcx
      mov r9, rax
      mov rax, rsi
      mov r10, 0
  absurd_percent_digit_loop:
      cmp r9, 0
      jne absurd_percent_digit_loop_nonzero
      push 0
      inc r10
      jmp absurd_percent_digit_loop_end
  absurd_percent_digit_loop_nonzero:
      cmp r9, 0
      jle absurd_percent_digit_loop_end
      mov rax, r9
      mov rcx, 10
      xor rdx, rdx
      div rcx
      push rdx
      mov r9, rax
      inc r10
      jmp absurd_percent_digit_loop_nonzero
  absurd_percent_digit_loop_end:
      mov rax, rsi
      mov r15, 0
  absurd_percent_digit_draw_loop:
      cmp r15, r10
      jge absurd_percent_digit_draw_loop_end
      call get_index
      pop rcx
      add rcx, 48
      mov byte [draw_buffer + rdx], cl
      inc r15
      inc rax
      jmp absurd_percent_digit_draw_loop
  absurd_percent_digit_draw_loop_end:
      call get_index
      mov byte [draw_buffer + rdx], '%'
      inc rax
      call get_index
      mov byte [color_buffer + rdx], '?'

  draw_numbers_end:

  mov rax, 1
  mov rdi, 1
  mov rsi, clear_terminal
  mov rdx, clear_terminal_length
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, cursor_start
  mov rdx, cursor_start_length
  syscall

  mov rdi, 0

  y_loop_draw:
    mov rax, 0
    cmp rdi, draw_buffer_y_size
    jge y_loop_draw_end

    x_loop_draw:
      cmp rax, draw_buffer_x_size
      jge x_loop_draw_end
      push rax
      push rdi
      call get_index
      mov r13, rdx

      cmp byte [color_buffer + r13], 1
      je red

      cmp byte [color_buffer + r13], 2
      je white

      cmp byte [color_buffer + r13], 3
      je green

      cmp byte [color_buffer + r13], 4
      je light_blue

      cmp byte [color_buffer + r13], 5
      je purple
      
      cmp byte [color_buffer + r13], 6
      je blue

      cmp byte [color_buffer + r13], 7
      je lavender

      cmp byte [color_buffer + r13], '?'
      je reset_color

      jmp color_end

      red:
          mov rax, 1
          mov rdi, 1
          mov rsi, red_seq
          mov rdx, red_len
          syscall
          jmp color_end

      white:
          mov rax, 1
          mov rdi, 1
          mov rsi, white_seq
          mov rdx, white_len
          syscall
          jmp color_end

      green:
          mov rax, 1
          mov rdi, 1
          mov rsi, green_seq
          mov rdx, green_len
          syscall
          jmp color_end

      light_blue:
          mov rax, 1
          mov rdi, 1
          mov rsi, light_blue_seq
          mov rdx, light_blue_len
          syscall
          jmp color_end

      purple:
          mov rax, 1
          mov rdi, 1
          mov rsi, purple_seq
          mov rdx, purple_len
          syscall
          jmp color_end

      blue:
          mov rax, 1
          mov rdi, 1
          mov rsi, blue_seq
          mov rdx, blue_len
          syscall
          jmp color_end

      lavender:
          mov rax, 1
          mov rdi, 1
          mov rsi, lavender_seq
          mov rdx, lavender_len
          syscall
          jmp color_end

      reset_color:
          mov rax, 1
          mov rdi, 1
          mov rsi, reset_color_seq
          mov rdx, reset_color_len
          syscall
          jmp color_end

      color_end:

      mov rax, 1
      mov rdi, 1
      lea rsi, [draw_buffer + r13]
      mov rdx, 1
      syscall
      pop rdi
      pop rax
      inc rax
      jmp x_loop_draw
    x_loop_draw_end:

    push rax
    push rdi
    mov rax, 1
    mov rdi, 1
    mov rsi, new_line
    mov rdx, 1
    syscall
    pop rdi
    pop rax
    inc rdi
    jmp y_loop_draw
  y_loop_draw_end:

  ret

main:
    mov eax, 318
    lea rdi, [state]
    mov esi, 16
    xor edx, edx
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, locked_terminal
    mov rdx, locked_terminal_length
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, enable_mouse
    mov rdx, enable_mouse_length
    syscall

    call set_raw_mode
    call draw

    input_loop:
      call get_char
      mov al, [terminal_input]
      cmp al, 'q'
      je main_end
      cmp al, 'r'
      je click

      cmp al, 's'
      je save_check
      jmp save_check_end

      save_check:
        call save
        jmp input_loop

      save_check_end:

      cmp al, 'l'
      je load_check
      jmp load_check_end

      load_check:
        call load
        call draw
        jmp input_loop

      load_check_end:
        jmp check_for_click

    check_for_click:
      cmp al, 27
      jne input_loop
      call get_char       
      call get_char
      call get_char
      call get_char
      mov bl, [terminal_input]
      sub bl, 32
      cmp bl, 3
      je input_loop
      call get_char
      mov cl, [terminal_input]
      sub cl, 32
      cmp cl, 13
      jl input_loop
      cmp cl, 15
      jg input_loop
      mov al, bl
      cmp al, (draw_buffer_x_size / 2) - 12
      jl input_loop
      cmp al, (draw_buffer_x_size / 2) + 11
      jg input_loop

      mov [mouse_down], 1
      call draw

    wait_until_mouse_up:
      call get_char
      mov al, [terminal_input]
      cmp al, 27
      jne input_loop

      call get_char
      call get_char
      call get_char
      call get_char

      mov bl, [terminal_input]
      sub bl, 32
      cmp bl, 3
      je wait_until_mouse_up
      jmp wait_until_mouse_up_end
    wait_until_mouse_up_end:

    click:
      mov [mouse_down], 0
      call next
      xor rdx, rdx
      mov rcx, max_number
      div rcx
      push rdx
      mov rax, rdx
      mov rcx, 10
      mov r11, 5
      digit_extract_loop:
        cmp r11, 0
        jl digit_extract_loop_end
        xor rdx, rdx
        div rcx
        mov [numbers + r11], dl
        dec r11
        jmp digit_extract_loop
      digit_extract_loop_end:
      pop rdx
      call calculate_ep
      add [lifetime_ep], rax      
      inc qword [attempts]
      mov [current], rax

      mov rdx, rax
      call get_rarity
      mov byte [current + 8], al

      cmp byte [history_index], 7
      jge overwrite_history
      xor rax, rax

      append_history:
        mov al, [history_index]
        call get_history_index
        
        mov rsi, numbers
        mov rdi, history
        add rdi, rdx
        mov rcx, 6
        rep movsb

        add rdx, 6
        mov rcx, [current + 8]
        mov [history + rdx], cl
        inc rdx

        mov rcx, [attempts]
        mov [history + rdx], rcx
        add rdx, 8
        mov rcx, [current]
        mov [history + rdx], rcx 

        add byte [history_index], 1 
        jmp history_end

      overwrite_history:
        call shift_history
        mov rax, 6
        call get_history_index
        
        mov rsi, numbers
        mov rdi, history
        add rdi, rdx
        mov rcx, 6
        rep movsb

        add rdx, 6
        mov rcx, [current + 8]
        mov [history + rdx], cl
        inc rdx

        mov rcx, [attempts]
        mov [history + rdx], rcx
        add rdx, 8
        mov rcx, [current]
        mov [history + rdx], rcx

      history_end:

      mov r14b, [current + 8]
      cmp r14b, 1
      je add_trash_numbers

      cmp r14b, 2
      je add_common_numbers

      cmp r14b, 3
      je add_uncommon_numbers

      cmp r14b, 4
      je add_rare_numbers

      cmp r14b, 5
      je add_anomaly_numbers

      cmp r14b, 6
      je add_legendary_numbers

      cmp r14b, 7
      je add_absurd_numbers

      jmp add_numbers_end

      add_trash_numbers:
        inc qword [trash_numbers]  
        jmp add_numbers_end

      add_common_numbers:
          inc qword [common_numbers]
          jmp add_numbers_end

      add_uncommon_numbers:
          inc qword [uncommon_numbers]
          jmp add_numbers_end

      add_rare_numbers:
          inc qword [rare_numbers]
          jmp add_numbers_end

      add_anomaly_numbers:
          inc qword [anomaly_numbers]
          jmp add_numbers_end

      add_legendary_numbers:
          inc qword [legendary_numbers]
          jmp add_numbers_end

      add_absurd_numbers:
          inc qword [absurd_numbers]

      add_numbers_end:

      xor r14b, r14b

      call draw
      jmp input_loop

main_end:
    ret

rotl:
  mov rax, r8
  mov rcx, r9
  shl rax, cl
  mov r10, 64
  sub r10, r9
  mov r11, r8
  mov rcx, r10
  shr r11, cl
  or rax, r11
  ret

next:
  mov r12, [state]
  mov r13, [state + 8]
  mov r14, r12
  add r14, r13
  push r14
  xor r13, r12
  mov r8, r12
  mov r9, 24
  call rotl
  mov r14, r13
  shl r14, 16
  xor rax, r13
  xor rax, r14
  mov qword [state], rax
  mov r8, r12
  mov r9, 37
  call rotl
  mov qword [state + 8], rax
  pop rax
  ret

calculate_ep:
  mov r12, rdx
  mov r13, 0

  mov rax, r12
  xor rdx, rdx
  mov rcx, 2
  div rcx

  mov r8, 1
  cmp rdx, 1
  call add_weight

  mov r8, 3
  cmp rdx, 0
  call add_weight

  mov r14, 3
  loop_divisible:
    cmp r14, 12
    jg loop_divisible_end
    mov rax, r12
    xor rdx, rdx
    mov rcx, r14
    div rcx
    mov r8, r14
    cmp rdx, 0
    call add_weight
    inc r14
    jmp loop_divisible
  loop_divisible_end:

  mov r14, 100
  loop_divisible_10:
    cmp r14, 100000
    jge loop_divisible_10_end
    mov rax, r12
    xor rdx, rdx
    mov rcx, r14
    div rcx
    mov r8, r14
    cmp rdx, 0
    call add_weight
    imul r14, 10
    jmp loop_divisible_10
  loop_divisible_10_end:
  
  cmp r12, 0
  je harshad_end

  mov r14, 0
  mov r10, 0
  loop_harshad:
    cmp r14, 6
    jge loop_harshad_end
    movzx r15, byte [numbers + r14]
    add r10, r15
    inc r14
    jmp loop_harshad
  loop_harshad_end:

  cmp r10, 0
  je harshad_end

  mov rax, r12
  xor rdx, rdx
  mov rcx, r10
  div rcx
  mov r8, 50
  cmp rdx, 0
  call add_weight

  harshad_end:

  mov r8, 999999
  cmp r12, 999999
  call add_weight
  mov r8, 314159
  cmp r12, 0
  call add_weight
  cmp r12, 314159
  call add_weight
  mov r8, 271828
  cmp r12, 271828
  call add_weight
  mov r8, 7777777
  cmp r12, 777777
  call add_weight

  mov r8, 182
  push r12
  call check_for_prime
  mov r8, 785
  add r12, 2
  call check_for_prime
  cmp r9, 100200100
  je check_for_prime_end
  sub r12, 4
  call check_for_prime
  check_for_prime_end:
  pop r12

  mov r8, 42
  mov r14, 42
  call contains_double_string
  mov r8, 67
  mov r14, 67
  call contains_double_string
  mov r8, 69
  mov r14, 69
  call contains_double_string

  mov r8, 333
  mov r14, 333
  call contains_triple_string
  mov r8, 666
  mov r14, 666
  call contains_triple_string
  mov r8, 777
  mov r14, 777
  call contains_triple_string
  mov r8, 911
  mov r14, 911
  call contains_triple_string
  mov r8, 314
  mov r14, 314
  call contains_triple_string
  mov r8, 271
  mov r14, 271
  call contains_triple_string

  mov r8, 7777
  mov r14, 7777
  call contains_quadruple_string
  mov r8, 1337
  mov r14, 1337
  call contains_quadruple_string
  mov r8, 1541
  mov r14, 1541
  call contains_quadruple_string
  mov r8, 1984
  mov r14, 1984
  call contains_quadruple_string
  mov r8, 3141
  mov r14, 3141
  call contains_quadruple_string
  mov r8, 2717
  mov r14, 2718
  call contains_quadruple_string

  mov r8, 77777
  mov r14, 77777
  call contains_quintuple_string
  mov r8, 31415
  mov r14, 31415
  call contains_quintuple_string
  mov r8, 27172
  mov r14, 27182
  call contains_quintuple_string

  mov r15, 0
  mov r8, 625

  palindrome_loop:
    cmp r15, 6
    jge palindrome_add
    movzx rax, byte [numbers + r15]
    mov r14, 5
    sub r14, r15
    movzx r11, byte [numbers + r14]
    cmp rax, r11
    jne palindrome_loop_end
    inc r15
    jmp palindrome_loop
  palindrome_add:
    mov r9, 0
    cmp r9, 0
    call add_weight
  palindrome_loop_end:

  mov r8, 16384
  mov r9, 2
  call is_power
  cmp rax, 1
  call add_weight

  mov r8, 6561
  mov r9, 3
  call is_power
  cmp rax, 1
  call add_weight

  mov r8, 3125
  mov r9, 5
  call is_power
  cmp rax, 1
  call add_weight

  mov r8, 2401
  mov r9, 7
  call is_power
  cmp rax, 1
  call add_weight

  mov r8, 1331
  mov r9, 11
  call is_power
  cmp rax, 1
  call add_weight

  mov r8, 25
  movzx rax, byte [numbers + 0]
  movzx r11, byte [numbers + 5]
  cmp rax, r11
  call add_weight

  mov r8, 125
  movzx rax, byte [numbers + 0]
  imul rax, 10
  movzx r11, byte [numbers + 1]
  add rax, r11

  movzx rdx, byte [numbers + 4]
  imul rdx, 10
  movzx r11, byte [numbers + 5]
  add rdx, r11

  cmp rax, rdx
  call add_weight
  cmp rax, rdx
  je sym_digits_end

  movzx rdx, byte [numbers + 5]
  imul rdx, 10
  movzx r11, byte [numbers + 4]
  add rdx, r11
  call add_weight

  sym_digits_end:

  mov r8, 123456
  cmp r12, 123456
  call add_weight
  cmp r12, 123456
  je end_digit_sequence

  mov r8, 123

  mov r14, 123
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 234
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 345
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 456
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple
  
  mov r14, 567
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 678
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 789
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 987
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 876
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 765
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 654
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 543
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 432
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  mov r14, 321
  call contains_triple_string
  cmp r9, 100200100
  je ascending_quadruple

  ascending_quadruple:

  mov r8, 1234

  mov r14, 1234
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 2345
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 3456
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 4567
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 5678
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 6789
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 9876
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 8765
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 7654
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 6543
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 5432
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  mov r14, 4321
  call contains_quadruple_string
  cmp r9, 100200100
  je ascending_quintuple

  ascending_quintuple:

  mov r8, 12345

  mov r14, 12345
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 23456
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence
  
  mov r14, 34567
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 45678
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 56789
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 98765
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 87654
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 76543
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 65432
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  mov r14, 54321
  call contains_quintuple_string
  cmp r9, 100200100
  je end_digit_sequence

  end_digit_sequence:

  mov r8, 6
  movzx rax, byte [numbers + 0]
  cmp rax, 0
  call add_weight

  mov r8, 10101
  mov rax, 0
  check_binary_number:
    cmp rax, 6
    jge check_binary_number_add_weight
    movzx r11, byte [numbers + rax]
    cmp r11, 0
    je is_binary_one_end
    cmp r11, 1
    jne check_binary_number_end
    is_binary_one_end:
    inc rax
    jmp check_binary_number
  check_binary_number_add_weight:
    mov rax, 0
    cmp rax, 0
    call add_weight
  check_binary_number_end:

  mov r8, 2585
  movzx rax, byte [numbers + 0]
  imul rax, 10
  movzx r11, byte [numbers + 1]
  add rax, r11

  movzx r14, byte [numbers + 2]
  imul r14, 10
  movzx r11, byte [numbers + 3]
  add r14, r11

  movzx r15, byte [numbers + 4]
  imul r15, 10
  movzx r11, byte [numbers + 5]
  add r15, r11
  
  cmp rax, r14
  jne xy1_xy2_not_match
  xy1_xy2_match:
    cmp rax, r15
    call add_weight
    cmp rax, r15
    je pattern_check_end
  xy1_xy2_not_match:
    mov r8, 3135
    movzx rax, byte [numbers + 0]
    imul rax, 100
    movzx r11, byte [numbers + 1]
    imul r11, 10
    add rax, r11
    movzx r11, byte [numbers + 2]
    add rax, r11

    movzx rdx, byte [numbers + 3]
    imul rdx, 100
    movzx r11, byte [numbers + 4]
    imul r11, 10
    add rdx, r11
    movzx r11, byte [numbers + 5]
    add rdx, r11

    cmp rax, rdx
    call add_weight
  pattern_check_end:

  ; mov rdi, digit_array
  ; mov rcx, 10
  ; xor rax, rax
  ; rep stosb

  ; mov r8, 10
  ; mov rax, 0
  ; digit_count_loop:
  ;   cmp rax, 6
  ;   jge digit_count_loop_end
  ;   movzx rdx, byte [numbers + rax]
  ;   movzx r14, byte [digit_array + rdx]
  ;   inc r14
  ;   mov byte [digit_array + rdx], r14b
  ;   cmp byte [digit_array + rdx], 2
  ;   jge digit_count_loop_add_weight
  ;   inc rax
  ;   jmp digit_count_loop
  ; digit_count_loop_add_weight:
  ;   mov rax, 0
  ;   cmp rax, 0
  ;   call add_weight
  ; digit_count_loop_end:
  
  mov r8, 11
  mov r14, 11
  call contains_double_string

  mov r14, 22
  call contains_double_string

  mov r14, 33
  call contains_double_string

  mov r14, 44
  call contains_double_string

  mov r14, 55
  call contains_double_string

  mov r14, 66
  call contains_double_string

  mov r14, 77
  call contains_double_string

  mov r14, 88
  call contains_double_string

  mov r14, 99
  call contains_double_string
  
  mov r8, 111
  mov r14, 111
  call contains_triple_string

  mov r14, 222
  call contains_triple_string

  mov r14, 333
  call contains_triple_string

  mov r14, 444
  call contains_triple_string

  mov r14, 555
  call contains_triple_string

  mov r14, 666
  call contains_triple_string

  mov r14, 777
  call contains_triple_string

  mov r14, 888
  call contains_triple_string

  mov r14, 999
  call contains_triple_string

  mov r8, 1111
  mov r14, 1111
  call contains_quadruple_string

  mov r14, 2222
  call contains_quadruple_string

  mov r14, 3333
  call contains_quadruple_string

  mov r14, 4444
  call contains_quadruple_string

  mov r14, 5555
  call contains_quadruple_string

  mov r14, 6666
  call contains_quadruple_string

  mov r14, 7777
  call contains_quadruple_string

  mov r14, 8888
  call contains_quadruple_string

  mov r14, 9999
  call contains_quadruple_string

  mov r8, 11111
  mov r14, 11111
  call contains_quintuple_string

  mov r14, 22222
  call contains_quintuple_string

  mov r14, 33333
  call contains_quintuple_string

  mov r14, 44444
  call contains_quintuple_string

  mov r14, 55555
  call contains_quintuple_string

  mov r14, 66666
  call contains_quintuple_string

  mov r14, 77777
  call contains_quintuple_string

  mov r14, 88888
  call contains_quintuple_string

  mov r14, 99999
  call contains_quintuple_string

  mov rax, r13
  ret

is_power:
  mov rax, 0
  cmp r9, 1
  je check_power_of_1
  jmp pow_check

  check_power_of_1:
    mov r15, r12
    cmp r15, 1
    mov r14, 1
    cmove rax, r14
    jmp is_power_end

  pow_check:
    mov rdx, 1
  pow_loop:
    mov r15, r12
    cmp rdx, r15
    jge pow_loop_end
    imul rdx, r9
    jmp pow_loop
  pow_loop_end:
    mov r15, r12
    cmp rdx, r15
    mov r14, 1
    cmove rax, r14
  is_power_end:
  ret

check_for_prime:
  mov r9, 0
  cmp r12, 2
  call add_weight
  cmp r12, 2
  je prime_end
  mov rax, r12
  xor rdx, rdx
  mov rcx, 2
  div rcx
  cmp rdx, 0
  je prime_end
  mov r14, 3
  prime_loop:
    mov r15, r14
    imul r15, r15
    cmp r15, r12
    jg is_prime
    mov rax, r12
    xor rdx, rdx
    mov rcx, r14
    div rcx
    cmp rdx, 0
    je prime_end
    add r14, 2
    jmp prime_loop
  is_prime:
    mov r9, 100200100
    cmp r9, 100200100
    call add_weight
  prime_end:
  ret

contains_double_string:
  mov rsi, 0
  cd_loop:
    cmp rsi, 5
    jge cd_loop_end
    movzx rax, byte [numbers + rsi]
    imul rax, 10
    mov r15, rsi
    inc r15
    movzx r11, byte [numbers + r15]
    add rax, r11
    cmp rax, r14
    je cd_loop_give_points
    inc rsi
    jmp cd_loop
  cd_loop_give_points:
    mov r9, 100200100
    cmp r9, 100200100
    call add_weight
  cd_loop_end:
  ret

contains_triple_string:
  mov rsi, 0
  td_loop:
    cmp rsi, 4
    jge td_loop_end
    movzx rax, byte [numbers + rsi]
    imul rax, 100
    mov r15, rsi
    inc r15
    movzx r9, byte [numbers + r15]
    imul r9, 10
    add rax, r9
    mov r15, rsi
    add r15, 2
    movzx r11, byte [numbers + r15]
    add rax, r11
    cmp rax, r14
    je td_loop_give_points
    inc rsi
    jmp td_loop
  td_loop_give_points:
    mov r9, 100200100
    cmp r9, 100200100
    call add_weight
  td_loop_end:
  ret

contains_quadruple_string:
  mov rsi, 0
  qd_loop:
    cmp rsi, 3
    jge qd_loop_end
    movzx rax, byte [numbers + rsi]
    imul rax, 1000
    mov r15, rsi
    inc r15
    movzx r9, byte [numbers + r15]
    imul r9, 100
    add rax, r9
    mov r15, rsi
    add r15, 2
    movzx r9, byte [numbers + r15]
    imul r9, 10
    add rax, r9
    mov r15, rsi
    add r15, 3
    movzx r11, byte [numbers + r15]
    add rax, r11
    cmp rax, r14
    je qd_loop_give_points
    inc rsi
    jmp qd_loop
  qd_loop_give_points:
    mov r9, 100200100
    cmp r9, 100200100
    call add_weight
  qd_loop_end:
  ret

contains_quintuple_string:
  mov rsi, 0
  qtd_loop:
    cmp rsi, 2
    jge qtd_loop_end
    movzx rax, byte [numbers + rsi]
    imul rax, 10000
    mov r15, rsi
    inc r15
    movzx r9, byte [numbers + r15]
    imul r9, 1000
    add rax, r9
    mov r15, rsi
    add r15, 2
    movzx r9, byte [numbers + r15]
    imul r9, 100
    add rax, r9
    mov r15, rsi
    add r15, 3
    movzx r9, byte [numbers + r15]
    imul r9, 10
    add rax, r9
    mov r15, rsi
    add r15, 4
    movzx r11, byte [numbers + r15]
    add rax, r11
    cmp rax, r14
    je qtd_loop_give_points
    inc rsi
    jmp qtd_loop
  qtd_loop_give_points:
    mov r9, 100200100
    cmp r9, 100200100
    call add_weight
  qtd_loop_end:
  ret

add_weight:
  jne add_weight_end
  add_weight_condition:
    add r13, r8
add_weight_end:
  ret

get_rarity:
  ; rax - result
  ; rdx - ep
  ; 1 - trash
  ; 2 - common
  ; 3 - uncommon
  ; 4 - rare
  ; 5 - anomaly
  ; 6 - legendary
  ; 7 - absurd

  cmp rdx, 1000000
  mov r14, 6
  cmovle rax, r14
  mov r14, 7
  cmovg rax, r14

  cmp rdx, 100000
  mov r14, 5
  cmovle rax, r14

  cmp rdx, 10000
  mov r14, 4
  cmovle rax, r14
  
  cmp rdx, 1000
  mov r14, 3
  cmovle rax, r14

  cmp rdx, 100
  mov r14, 2
  cmovle rax, r14

  cmp rdx, 10
  mov r14, 1
  cmovle rax, r14

  ret

load:
    mov rax, 2
    mov rdi, savefile
    xor rsi, rsi
    xor rdx, rdx
    syscall

    test rax, rax
    js .open_failed

    mov r12, rax

    mov rax, 0
    mov rdi, r12
    mov rsi, data_start
    mov rdx, data_size
    syscall

    cmp rax, data_size
    jne .read_failed

    mov rax, 3
    mov rdi, r12
    syscall

    ret

.read_failed:
    mov rax, 3
    mov rdi, r12
    syscall
    ret

.open_failed:
    ret

save:
  mov rax, 2
  mov rdi, savefile
  mov rsi, 577
  mov rdx, 0o644
  syscall

  test rax, rax
  js open_failed

  mov r12, rax

  mov rax, 1
  mov rdi, r12
  mov rsi, data_start
  mov rdx, data_size
  syscall

  mov rax, 3
  mov rdi, r12
  syscall

  open_failed:
  ret