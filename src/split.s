.section .bss
    .extern fd
    .global temp_word
    .global temp_index
    .lcomm read_buf, 4096 # 4KB文件读取缓冲区
    .lcomm temp_word, 100 # 暂存当前读取的单词(MAX_WORD_LEN=100)
    .lcomm temp_index, 4 # 当前单词的长度

.section .text
.global split
    .type split, @function

split:
    pushl %ebp
    movl %esp, %ebp
    movl $0, temp_index

.read_loop: # 文件读取内容
    movl $3, %eax
    movl fd, %ebx           
    movl $read_buf, %ecx
    movl $4096, %edx
    int $0x80

    cmpl $0, %eax
    je .read_done # 读取结束，没有内容
    jl .read_error # 读取异常

    movl %eax, %ecx # ecx=读取到的字节数
    movl $read_buf, %esi # esi指向缓冲区开头

.process_char:
    pushl %ecx # 保存剩余字节数，防止被函数调用篡改
    movb (%esi), %al # 把当前字符取到al

    # 判断是否为大写字母
    cmpb $0x41, %al
    jl .not_alpha
    cmpb $0x5A, %al
    jle .is_upper

    # 判断是否为小写字母
    cmpb $0x61, %al
    jl .not_alpha
    cmpb $0x7A, %al
    jle .is_lower
    jmp .not_alpha

.is_upper:
    addb $32, %al
.is_lower:
    movl temp_index, %edx
    cmpl $99, %edx # 防止缓冲区溢出
    jge .next_char
    movl $temp_word, %edi
    addl %edx, %edi # edi=temp_word+temp_index
    movb %al, (%edi) # 保存字符
    incl temp_index
    jmp .next_char

.not_alpha:
    cmpl $0, temp_index
    jle .next_char # 连续非字母，跳过；否则说明一个单词结束，准备保存单词并统计
    movl temp_index, %edx
    movl $temp_word, %edi
    addl %edx, %edi
    movb $0, (%edi) # 添加字符串结束符'\0'
    call word_counter # 识别到一个单词，调用统计函数
    movl $0, temp_index # 重置index

.next_char:
    popl %ecx # 恢复剩余字节数
    incl %esi # 指针后移
    decl %ecx
    cmpl $0, %ecx
    jg .process_char # 继续处理当前缓冲区
    jmp .read_loop # 缓冲区处理完，继续读文件

.read_done:
    # 处理文件末尾没有非字母结尾的特殊情况，逻辑和.not_alpha几乎一样
    cmpl $0, temp_index
    jle .split_end
    movl temp_index, %edx
    movl $temp_word, %edi
    addl %edx, %edi
    movb $0, (%edi)
    call word_counter
    movl $0, temp_index

.split_end:
    movl %ebp, %esp
    popl %ebp
    ret

.read_error:
    call as_exit