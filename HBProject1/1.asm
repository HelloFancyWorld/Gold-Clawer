.386
.model flat, stdcall
option casemap:none

includelib      msvcrt.lib
printf          PROTO C :ptr sbyte, :VARARG
scanf           PROTO C :ptr sbyte, :VARARG

.data
ansMsg			byte    "������Ϣ���£�", 0ah, 0dh, "������������", 0ah, 0dh, "ѧ�ţ�2021011817", 0ah, 0dh, "�༶�����12��"  ; 0ah 0dh�ǻس�����

.code
start:
                invoke  printf, offset ansMsg
                ret
end				start