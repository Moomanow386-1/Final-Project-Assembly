global parse_func
global num1
global num2
global operator_p

extern clean

section .data
	text dq 0
	num1 dq 0
	num2 dq 0
	decBase dq 1
	convertNum dq 48
	operator_p dw 0

section .text
parse_func:
	mov	rsi, 0
	jmp	checkNum

checkNum:
	movzx	rax, byte[clean + rsi]
	inc	rsi

	cmp	rax, 0
	je	beforetxtToint2

	cmp	rax, 48
	jae	checkNum
	jb	getOperator

txtToint1:
	mov	rbx, qword[decBase]
	movzx	rax, byte[clean + (rsi - 1)]
	sub	rax, qword[convertNum]
	mul	rbx
	add	rax, qword[num1]
	mov	qword[num1], rax

	mov	rcx, 10
	mov	rax, rbx
	mul	rcx
	mov	qword[decBase], rax

	dec	rsi
	cmp	rsi, 0
	jne	txtToint1

	pop	rsi
	mov	rbx, 1
	mov	qword[decBase], rbx
	jmp	checkNum

beforetxtToint2:
	dec	rsi
	mov	rbx, 1
	mov	qword[decBase], rbx
	jmp	txtToint2

txtToint2:
	mov	rbx, qword[decBase]
	movzx	rax, byte[clean + (rsi - 1)]
	sub	rax, qword[convertNum]
	mul	rbx
	add	rax, qword[num2]
	mov	qword[num2], rax

	mov	rcx, 10
	mov	rax, rbx
	mul	rcx
	mov	qword[decBase], rax

	dec	rsi
	movzx	rax, byte[clean + (rsi - 1)]
	cmp	rax, 48
	jae	txtToint2

	jmp end

getOperator:
	mov	word[operator_p], ax

	push	rsi
	dec	rsi
	jmp	txtToint1

end:
	ret
	