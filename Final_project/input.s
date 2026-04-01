global input_func
global clean

section .data
  prompt db "Enter statement: "
  promptLen equ $-prompt

  errMsg db "Error: invalid input", 10
  errLen equ $-errMsg

section .bss
  input resb 50
  clean resb 50

section .text
input_func:

; LOOP รับ input จนถูก
input_start:

; print prompt
  mov rax, 1              ; เลือก syscall write
  mov rdi, 1              ; file descriptor = stdout
  mov rsi, prompt         ; address ของข้อความ
  mov rdx, promptLen      ; ความยาวข้อความ
  syscall                 ; เรียก OS ให้ print

; read input
  mov rax, 0              ; syscall read
  mov rdi, 0              ; stdin (keyboard)
  mov rsi, input          ; buffer ปลายทาง
  mov rdx, 50             ; อ่านสูงสุด 50 byte
  syscall                 ; อ่าน input

  cmp rax, 50
  jb ok_read

  flush_loop:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 1
    syscall

    cmp byte [input], 10
    jne flush_loop

ok_read:

; กัน input ยาวเกิน (buffer เต็ม = เสี่ยงไม่มี newline)
  cmp rax, 50             ; rax = จำนวน byte ที่อ่านได้
  je error_input          ; ถ้าเต็ม buffer → error

; CLEAN + VALIDATE
  mov rsi, input          ; rsi = pointer อ่าน
  mov rdi, clean          ; rdi = pointer เขียน

  xor rcx, rcx            ; rcx = operator count = 0
  xor rbx, rbx            ; rbx = digit count = 0

clean_loop:
  mov al, byte [rsi]      ; อ่าน char 1 ตัวจาก input

; จบเมื่อ newline
  cmp al, 10              ; '\n'
  je done_check           ; ไป validate

; กันหลุด memory
  cmp al, 0               ; null byte
  je done_check

; ข้าม space
  cmp al, ' '             ; ถ้าเป็นช่องว่าง
  je skip_char            ; ไม่ copy

; เช็ค digit
  cmp al, '0'             ; ถ้าน้อยกว่า '0'
  jb check_operator       ; ไปเช็ค operator
  cmp al, '9'
  jbe is_digit            ; อยู่ในช่วง digit

; เช็ค operator
check_operator:
  cmp al, '+'
  je is_operator
  cmp al, '-'
  je is_operator
  cmp al, '*'
  je is_operator
  cmp al, '/'
  je is_operator

  jmp error_input         ; ตัวอื่น = invalid

; digit
is_digit:
  inc rbx                 ; นับจำนวน digit
  jmp copy_char           ; ไป copy

; operator
is_operator:
  inc rcx                 ; นับ operator
  cmp rcx, 1
  ja error_input          ; เกิน 1 ตัว = error

; copy ลง clean
copy_char:
  mov byte [rdi], al      ; เขียน char ลง clean
  inc rdi                 ; pointer clean++

skip_char:
  inc rsi                 ; pointer input++
  jmp clean_loop          ; loop ต่อ

; FINAL VALIDATION
done_check:

; ต้องมี operator 1 ตัว
  cmp rcx, 1
  jne error_input

; ต้องมี digit อย่างน้อย 2 ตัว
  cmp rbx, 2
  jb error_input

; string ต้องไม่ว่าง
  mov rax, rdi            ; rax = end pointer
  sub rax, clean          ; rax = length
  cmp rax, 0
  je error_input

; operator ห้ามอยู่หน้า
  mov al, byte [clean]    ; ตัวแรก

  cmp al, '+'
  je error_input
  cmp al, '-'
  je error_input
  cmp al, '*'
  je error_input
  cmp al, '/'
  je error_input

; operator ห้ามอยู่ท้าย
  mov rax, rdi            ; pointer end
  dec rax                 ; ไปตัวสุดท้าย
  mov al, byte [rax]

  cmp al, '+'
  je error_input
  cmp al, '-'
  je error_input
  cmp al, '*'
  je error_input
  cmp al, '/'
  je error_input

; จบ string
mov byte [rdi], 0       ; null terminate

; DEBUG print clean string
;mov rax, 1              ; syscall write
;mov rdi, 1              ; stdout
;mov rsi, clean          ; address ของ clean
;mov rdx, 50
;syscall

ret

; ERROR HANDLER
error_input:
  mov rax, 1              ; syscall write
  mov rdi, 1              ; stdout
  mov rsi, errMsg         ; error message
  mov rdx, errLen
  syscall

  jmp input_start         ; วนรับใหม่

