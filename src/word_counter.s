.section .bss
    .global dictionary
    .global dict_size
    .extern temp_word # split中刚刚分离出来的那个单词
    .lcomm dictionary, 2080000 # MAX_WORDS(20000)*sizeof(WordRecord)(104)
    .lcomm dict_size, 4

.section .text
.global word_counter
    .type word_counter, @function

word_counter:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx
    pushl %esi
    pushl %edi

    movl $0, %ecx # ecx=i=0
.check_loop:
    cmpl dict_size, %ecx
    jge .add_new_word # 遍历结束没找到，添加新词

    movl %ecx, %eax
    imull $104, %eax # 一个结构体元素占100+4=104
    leal dictionary(%eax), %edi # 计算dictionary[i].word 地址，存在edi
    movl $temp_word, %esi # esi=要比较的单词

.strcmp_loop: # 本质还是逐字符匹配，不匹配就下一个单词，如果到'\0'就完成匹配
    movb (%esi), %al
    movb (%edi), %bl
    cmpb %bl, %al
    jne .next_word # 字符不匹配，跳到下一个单词
    cmpb $0, %al
    je .found_word # 到达 '\0' 且完全匹配，跳出循环
    incl %esi
    incl %edi
    jmp .strcmp_loop

.next_word:
    incl %ecx
    jmp .check_loop

.found_word: # 找到单词，dictionary[i].count++
    movl %ecx, %eax
    imull $104, %eax
    leal dictionary(%eax), %edi # edi为dictionary[i]的后一个地址，即dictionary[i+1]的首地址
    incl 100(%edi) # count的偏移量为100，count++
    jmp .end_counter

.add_new_word:
    cmpl $20000, dict_size
    jge .end_counter # 字典已满，直接忽略
    # 准备写入新词
    movl dict_size, %eax
    imull $104, %eax
    leal dictionary(%eax), %edi # edi指向dictionary[i]
    movl $temp_word, %esi

.strcpy_loop:
    movb (%esi), %al # al只是中转寄存器，本质是(esi)->(edi)
    movb %al, (%edi)
    cmpb $0, %al # '\0'则结束复制
    je .strcpy_done
    incl %esi
    incl %edi
    jmp .strcpy_loop

.strcpy_done:
    # 设置 count = 1，dict_size++
    movl dict_size, %eax
    imull $104, %eax
    leal dictionary(%eax), %edi
    movl $1, 100(%edi)
    incl dict_size

.end_counter:
    popl %edi
    popl %esi
    popl %ebx
    movl %ebp, %esp
    popl %ebp
    ret