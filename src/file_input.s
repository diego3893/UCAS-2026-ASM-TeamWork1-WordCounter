.section .rodata
filename:
    .string "test/data.in" 

.section .bss
    .global fd  # 文件描述符，全局，向split传递参数
    .type fd, @object
    .size fd, 4
fd:
    .zero 4                 

.section .text
.global file_input
    .type file_input, @function

file_input:
    pushl %ebp
    movl %esp, %ebp

    movl $5, %eax           # 开文件
    movl $filename, %ebx
    movl $0, %ecx
    movl $0, %edx
    int $0x80

    cmpl $0, %eax
    jl .open_failed

    movl %eax, fd # 把描述符存到fd

    movl %ebp, %esp
    popl %ebp
    ret

.open_failed:
    call as_exit