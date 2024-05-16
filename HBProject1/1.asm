.386
.model flat, stdcall
option casemap:none

includelib      msvcrt.lib
printf          PROTO C :ptr sbyte, :VARARG
scanf           PROTO C :ptr sbyte, :VARARG

.data
ansMsg			byte    "个人信息如下：", 0ah, 0dh, "姓名：刘子张", 0ah, 0dh, "学号：2021011817", 0ah, 0dh, "班级：软件12班"  ; 0ah 0dh是回车换行

.code
start:
                invoke  printf, offset ansMsg
                ret
end				start