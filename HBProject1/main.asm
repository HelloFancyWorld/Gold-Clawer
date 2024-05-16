TITLE Windows Application (WinApp_v2.asm)
; Another version of WinApp.asm
; Modified by: HenryFox
; Last update: 10/13/21
; Original version uses Irvine32 and GraphWin, this version uses windows.inc
; This program displays a resizable application window and
; several popup message boxes.
; Thanks to Tom Joyce for creating a prototype
; from which this program was derived.
.386
.model flat, stdcall
option casemap: none
include windows.inc
include gdi32.inc
includelib gdi32.lib
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include masm32.inc
includelib masm32.lib
include msvcrt.inc   
includelib msvcrt.lib
include shell32.inc
includelib shell32.lib
include winmm.inc
includelib winmm.lib

;------------------ Structures ----------------
WNDCLASS STRUC
style DWORD ?
lpfnWndProc DWORD ?
cbClsExtra DWORD ?
cbWndExtra DWORD ?
hInstance DWORD ?
hIcon DWORD ?
hCursor DWORD ?
hbrBackground DWORD ?
lpszMenuName DWORD ?
lpszClassName DWORD ?
WNDCLASS ENDS
MSGStruct STRUCT
msgWnd DWORD ?
msgMessage DWORD ?
msgWparam DWORD ?
msgLparam DWORD ?
msgTime DWORD ?
msgPt POINT <>
MSGStruct ENDS
MAIN_WINDOW_STYLE = WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU \
+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME



;==================== DATA =======================
.data

; ��Ʒ�ṹ��
Item STRUCT
	exist DWORD ?; 1���ڣ�0�Ѳ�����
	typ DWORD ?; ���, 0 stone, 1 bag, 2 gold
	posX DWORD ?; λ�ú�����
	posY DWORD ?; λ��������
	item_width DWORD ?; �ߴ磨Ӱ���ֵ��
	speed DWORD ?; �ٶ�
	value DWORD ?; ��ֵ������ͼ�ֵ��������TODO��
Item ENDS; һ��ʵ��ռ4*7=28B
Items Item 50 DUP({}); �����б�(�����50������)

itemNum dd 14
itemLeft dd 0

; ���ӵ�width��height
hookPosX dd 0
hookPosY dd 180
hookWidth dd 48
halfhookWidth dd 24
quarterhookWidth dd 12
hookHeight dd 37

diggerPosY dd 60

; ������ײ��Ԫ��index
hitItem dd 100
bombNum dd 0
randBagtag dd 0
speedNum dd 0
stonevNum dd 0
strengthNum dd 0

;�����ƶ��ٶ�
strength dd 1
;�����ƶ��ٶ�
humanspeed dd 1
; ������
isMoving dd 0	;0��ֹ��1�˶�
; ƽ�кʹ�ֱ
HorizontalOrVertical dd 0 ; 0ƽ�У�1��ֱ


AppLoadMsgTitle BYTE "Application Loaded",0
AppLoadMsgText  BYTE "This window displays when the WM_CREATE "
	            BYTE "message is received",0

PopupTitle BYTE "Popup Window",0
PopupText  BYTE "This window was activated by a "
	       BYTE "WM_LBUTTONDOWN message",0

GreetTitle BYTE "Main Window Active",0
GreetText  BYTE "This window is shown immediately after "
	       BYTE "CreateWindow and UpdateWindow are called.",0

CloseMsg   BYTE "WM_CLOSE message received",0

ErrorTitle  BYTE "Error",0
WindowName  BYTE "ASM Windows App",0
className   BYTE "ASMWin",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?
startbmp DWORD ?
bgbmp DWORD ?
successbmp DWORD ?
failbmp DWORD ?
starticon DWORD ?
diggericon DWORD ?
bagicon1 DWORD ?
bagicon2 DWORD ?
bagicon3 DWORD ?
stoneicon1 DWORD ?
stoneicon2 DWORD ?
stoneicon3 DWORD ?
stoneicon4 DWORD ?
stoneicon5 DWORD ?
goldicon1 DWORD ?
goldicon2 DWORD ?
diamondicon DWORD ?
tnticon DWORD ?
lineicon DWORD ?
stonebook DWORD ?
powermed DWORD ?
speedmed DWORD ?
bombstack DWORD ?
hookup dd ?

hookicon DWORD ?
bgicon DWORD ?
randposx1 DWORD ?
randposx2 DWORD ?
randposx3 DWORD ?
randposy1 DWORD ?
randposy2 DWORD ?
randposy3 DWORD ?
ps PAINTSTRUCT <>
cpthdc dd 0
isDrawingIcon db TRUE
isLeftClick dd 0	; 0�Ǿ�ֹ��1�����ң�2�����¡�
newGame dd 1
gametimeLeft dd 0
gametimeShow dd 0
hookismoving dd 0
range db FALSE
range2 dd 0
firstDraw db TRUE
startPage db TRUE
successPage db FALSE
failPage db FALSE
stone2gold dd 0
timerId dd 0
interval dd 500
startcatching dd 0
randNum dd 9
tempPosX dd 0
tempPosY dd 0
totalValue dd 0
tempSpeed dd 0


stageIndex dd 1
stageTarget dd ?


temp0 dd ?
temp1 dd ?
temp2 dd ?
temp3 dd ?

PointText db "��ǰ�ؿ���%d.   ��ǰ������%d.  ʣ��ʱ�䣺%d ��.                                            X%d                 X%d                X%d               X%d",0 
startText db "˫����ʼ��Ϸ��",0

readmeText  db "��ӭ�������ǵĻƽ����Ϸ���ڱ���Ϸ�У��㽫�ٿػƽ���ù���ץȡ��Ʒ������60s��ʱ����ץȡ��Ʒ���(400+600*�ؿ���)�ķ���������ɹ��������һ�أ����򷵻ؿ�ʼҳ�档��������ʱ��������Ϸ��������Ϸ���", 0ah, 0dh
			db "���������������´�ֱ��������������ץ��������ߴ��׺���Զ����ء����غ��ٴε�����������󹤽������˶���ÿһ�ص���Ʒλ��Ϊ������ɣ�������С��󡢴�Сʯ�顢��ʯ��TNT�������Ʒ����", 0ah, 0dh
			db "����ʯ���и��ߵļ�ֵ����ʯ��ֵ��ߣ��������ƷҲ���Ÿ��ߵļ�ֵ����Ҳ������������ص��ٶȡ�ץ��TNT��ֱ����Ϸʧ�ܡ������Ʒ������������Ʒ����ʯͷ�ղ��飨�����ڱ���������ץ����ʯͷ��ֵ��ߣ���"
			db "�����裨����Ĺ���������ץ������ʱ�ٶȱ�죩������ҩ����������ﱾ�����˶��ٶȱ�죩��ըҩ��������Ե���ո�ը��Ŀǰץ���Ķ�������", 0ah, 0dh
			db "����õ�����Ʒ����ʾ�ڷ�����ʱ�������Ҳ࣬���1��2��3��4����ʹ�ö�Ӧ��Ʒ��",0
readmeTitle db "��Ϸ˵��", 0


modelMusicset_xpx byte "..\Source\music\set_xpx.mp3", 0
modelMusicboomb byte "..\Source\music\boomb.mp3", 0
modelMusicstartgame byte "..\Source\music\startgame.mp3", 0

modelMusicset_xpxP dd 0
modelMusicboombP dd 0
modelMusicstartgameP dd 0

PointBuffer byte 1024 dup (?)
readmeBuffer byte 1024 dup (?)
PonintTextLen equ $ - text
clientRect RECT <>;
readmeRect RECT <>

;=================== CODE =========================
.code
WinMain PROC
; Get a handle to the current process.

	
	
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	mov MainWin.hInstance, eax

; Load the program's icon and cursor.


	INVOKE LoadIcon, NULL, 106
	mov MainWin.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov MainWin.hCursor, eax

; Register the window class.
	INVOKE RegisterClass, ADDR MainWin
	.IF eax == 0
	  call ErrorHandler
	  jmp Exit_Program
	.ENDIF

; Create the application's main window.
; Returns a handle to the main window in EAX.
	INVOKE CreateWindowEx, 0, ADDR className,
	  ADDR WindowName,MAIN_WINDOW_STYLE,
	  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
	  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
	mov hMainWnd,eax

; If CreateWindowEx failed, display a message & exit.
	.IF eax == 0
	  call ErrorHandler
	  jmp  Exit_Program
	.ENDIF

; Show and draw the window.
	INVOKE ShowWindow, hMainWnd, SW_SHOW
	INVOKE UpdateWindow, hMainWnd
;Start timer
    ;INVOKE SetTimer,hMainWnd,1,interval,NULL
	;mov timerId,eax
; Display a greeting message.
;	INVOKE MessageBox, hMainWnd, ADDR GreetText,
;	  ADDR GreetTitle, MB_OK


; Begin the program's message-handling loop.
Message_Loop:
	; Get next message from the queue.
	INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

	; Quit if no more messages.
	.IF eax == 0
	  jmp Exit_Program
	.ENDIF

	; Relay the message to the program's WinProc.
	INVOKE DispatchMessage, ADDR msg
    jmp Message_Loop

Exit_Program:
      INVOKE KillTimer,hMainWnd,timerId
	  INVOKE ExitProcess,0
WinMain ENDP

; ���stone����
AddStoneItem PROC, posx:DWORD, posy:DWORD, itemwidth:DWORD
	
	; ����Ҫ���Ԫ�ص�λ���ڽṹ�������е�ƫ����
	mov eax, itemLeft
	imul eax, 28 ; SIZEOF Item��28
	; ���ƽṹ�������ֵ���ṹ������
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��

    ; ����Ԫ�صĵ�ַ�������
	mov eax, 1
    mov [edi], eax       ; exist = 1
	mov eax, 0
	mov [edi + 4], eax   ; type = 0
	mov eax, posx
	mov [edi + 8], eax  ; posX
	mov eax, posy
	mov [edi + 12], eax   ; posY
	mov eax, itemwidth
	mov [edi + 16], eax   ; width
	.IF itemwidth <= 50
		mov eax, 6
	.ELSEIF itemwidth <= 100
		mov eax, 4
	.ELSE
		mov eax, 2
	.ENDIF
	mov [edi + 20], eax   ; speed
	mov eax, 1
	imul eax, itemwidth
	mov [edi + 24], eax   ; value = w*w*10
		
	; ��������Ԫ�ظ���
	INC itemLeft
	ret
AddStoneItem ENDP

; ���bag����
AddBagItem PROC, posx:DWORD, posy:DWORD, itemwidth:DWORD
	
	; ����Ҫ���Ԫ�ص�λ���ڽṹ�������е�ƫ����
	mov eax, itemLeft 
	imul eax, 28 ; SIZEOF Item��28
	; ���ƽṹ�������ֵ���ṹ������
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	
	; ����Ԫ�صĵ�ַ�������
	mov eax, 1
    mov [edi], eax       ; exist = 1
	mov eax, 1
	mov [edi + 4], eax   ; type = 1
	mov eax, posx
	mov [edi + 8], eax  ; posX
	mov eax, posy
	mov [edi + 12], eax   ; posY
	mov eax, itemwidth
	mov [edi + 16], eax   ; width
	mov eax, 10
	mov [edi + 20], eax   ; speed
	mov eax, 2
	imul eax, itemwidth
	mov [edi + 24], eax   ; value = 10 ��TODO:�������

	; ��������Ԫ�ظ���
	INC itemLeft
	ret
AddBagItem ENDP

; ���gold����
AddGoldItem PROC, posx:DWORD, posy:DWORD, itemwidth:DWORD
	
	; ����Ҫ���Ԫ�ص�λ���ڽṹ�������е�ƫ����
	mov eax, itemLeft
	imul eax, 28 ; SIZEOF Item��28
	; ���ƽṹ�������ֵ���ṹ������
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��

    ; ����Ԫ�صĵ�ַ�������
	mov eax, 1
    mov [edi], eax       ; exist = 1
	mov eax, 2
	mov [edi + 4], eax   ; type = 2
	mov eax, posx
	mov [edi + 8], eax  ; posX
	mov eax, posy
	mov [edi + 12], eax   ; posY
	mov eax, itemwidth
	mov [edi + 16], eax   ; width
	.IF itemwidth <= 50
		mov eax, 7
	.ELSEIF itemwidth <= 100
		mov eax, 5
	.ELSE
		mov eax, 3
	.ENDIF
	mov [edi + 20], eax   ; speed
	mov eax, 5
	imul eax, itemwidth
	mov [edi + 24], eax   ; value = 100
	
	; ��������Ԫ�ظ���
	INC itemLeft
	ret
AddGoldItem ENDP

; ���diamond����
AddDiamondItem PROC, posx:DWORD, posy:DWORD, itemwidth:DWORD
	
	; ����Ҫ���Ԫ�ص�λ���ڽṹ�������е�ƫ����
	mov eax, itemLeft 
	imul eax, 28 ; SIZEOF Item��28
	; ���ƽṹ�������ֵ���ṹ������
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	
	; ����Ԫ�صĵ�ַ�������
	mov eax, 1
    mov [edi], eax       ; exist = 1
	mov eax, 1
	mov [edi + 4], eax   ; type = 3
	mov eax, posx
	mov [edi + 8], eax  ; posX
	mov eax, posy
	mov [edi + 12], eax   ; posY
	mov eax, itemwidth
	mov [edi + 16], eax   ; width
	mov eax, 10
	mov [edi + 20], eax   ; speed
	mov eax, 500
	mov [edi + 24], eax   ; value = 500

	; ��������Ԫ�ظ���
	INC itemLeft
	ret
AddDiamondItem ENDP


; ���TNT����
AddTNTItem PROC, posx:DWORD, posy:DWORD, itemwidth:DWORD
	
	; ����Ҫ���Ԫ�ص�λ���ڽṹ�������е�ƫ����
	mov eax, itemLeft 
	imul eax, 28 ; SIZEOF Item��28
	; ���ƽṹ�������ֵ���ṹ������
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	
	; ����Ԫ�صĵ�ַ�������
	mov eax, 1
    mov [edi], eax       ; exist = 1
	mov eax, 1
	mov [edi + 4], eax   ; type = 4
	mov eax, posx
	mov [edi + 8], eax  ; posX
	mov eax, posy
	mov [edi + 12], eax   ; posY
	mov eax, itemwidth
	mov [edi + 16], eax   ; width
	mov eax, 0
	mov [edi + 20], eax   ; speed
	mov eax, 0
	mov [edi + 24], eax   ; value = 0

	; ��������Ԫ�ظ���
	INC itemLeft
	ret
AddTNTItem ENDP

;��ȡ������
getPosX PROC, index:DWORD
	mov eax, index
	imul eax, 28 ; SIZEOF Item��28
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	mov eax, [edi+8]
	ret
getPosX ENDP
;��ȡ������
getPosY PROC, index:DWORD
	mov eax, index
	imul eax, 28 ; SIZEOF Item��28
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	mov eax, [edi+12]
	ret
getPosY ENDP
;��ȡ�ٶ�
getSpeed PROC, index:DWORD
	mov eax, index
	imul eax, 28 ; SIZEOF Item��28
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	mov eax, [edi+20]
	ret
getSpeed ENDP
;��ȡ��ֵ
getValue PROC, index:DWORD
	mov eax, index
	imul eax, 28 ; SIZEOF Item��28
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	mov eax, [edi+24]
	ret
getValue ENDP
 
;���´���״̬
ExistNoLonger PROC, index:DWORD
	INVOKE sndPlaySound,122, SND_ASYNC or SND_RESOURCE
	INVOKE getValue, index
	.IF index>=3
	 .IF index<=8
	  .IF stone2gold!=0
	    add eax,200
		DEC stone2gold
	  .ENDIF
	 .ENDIF
	.ENDIF
	mov ecx, totalValue
	add ecx, eax
	mov totalValue, ecx
	mov eax, index
	imul eax, 28 ; SIZEOF Item��28
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	mov eax, 0
	mov [edi], eax
	DEC itemLeft
	ret
ExistNoLonger ENDP

BombedOut PROC, index:DWORD
	;INVOKE loadSound,addr modelMusicboomb,addr modelMusicboombP
	;INVOKE playSound,modelMusicboombP,0
	INVOKE sndPlaySound,126, SND_ASYNC or SND_RESOURCE
	INVOKE getValue, index
	mov eax, index
	imul eax, 28 ; SIZEOF Item��28
	mov edi, OFFSET Items  ; ������ĵ�ַ���浽 EDI �Ĵ�����
	add edi, eax       ; ����ƫ������ָ��Ҫ���Ԫ�ص�λ��
	mov eax, 0
	mov [edi], eax
	DEC itemLeft
	DEC bombNum
	ret
BombedOut ENDP

RandomBag PROC
		push 0
		call crt_time
		add esp, 4
		push eax
		call crt_srand
		add esp, 4
		invoke crt_rand; �����������������eax��
		mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
		mov ebx, 8;
		div ebx; ����0~9����edx��	
		mov randBagtag, edx
		.IF randBagtag < 2
		mov eax,bombNum
		inc eax
		mov bombNum, eax
		.ELSEIF edx < 4 
		mov eax,speedNum
		inc eax
		mov speedNum, eax
		.ELSEIF edx < 6
		mov eax,stonevNum
		inc eax
		mov stonevNum, eax
		.ELSEIF edx < 8
		mov eax, strengthNum
		inc eax
		mov strengthNum, eax
		.ENDIF
RandomBag ENDP

;��ײ��⺯��
IsHit PROC
		pushad
		mov edi, OFFSET Items  ;��ʼ����������
		mov temp0, 0
		cmp itemLeft, 0
		je Finish
	LoopTraverseItem:
		mov eax, [edi]
		mov temp1, eax
		.IF temp1 == 1
			mov eax, [edi + 8]
			mov temp2, eax ;Items[edi].posX
			mov ebx, halfhookWidth
			add ebx, hookPosX
			cmp temp2, ebx
			jg not_case	;�ұ߽� posX < hookposX + 1/2 hookWidth < posX + width
			mov eax, [edi + 16]
			add temp2, eax ;Items[edi].posX + Items[edi].width
			sub ebx, quarterhookWidth
			cmp temp2, ebx
			jl not_case	;��߽�
			mov eax, [edi + 12]
			sub eax, 6
			mov temp2, eax ;Items[edi].posY - 6
			mov ebx, hookHeight
			add ebx, hookPosY
			cmp temp2, ebx
			jg not_case	;�±߽� posY - 6 < hookposY + hookHeight < posY
			add temp2, 6
			cmp temp2, ebx
			jl not_case	;�ϱ߽�
			jmp Hit			;������ײ���
		.ELSE
			jmp not_case
		not_case:
			add edi, 28; ���������±ꡣ���ڼӵ���28��һ���ṹ��Ԫ�صĴ�С
			mov eax, temp0
			inc eax
			mov temp0, eax
			cmp eax, itemNum; ���ѭ���Ƿ����,����������edi==itemNum*28
			jne LoopTraverseItem; ѭ��δ������������һ��ѭ��
			jmp Finish; ѭ��������δ���У���ת��Finish
		.ENDIF
	Hit:
		popad
		mov eax, temp0
		ret
	Finish:
		popad
		mov eax, 100
		ret
IsHit ENDP




;-----------------------------------------------------
WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler, which handles
; application-specific messages. All other messages
; are forwarded to the default Windows message
; handler.
;-----------------------------------------------------
	mov eax, localMsg

	.IF eax == WM_LBUTTONDOWN		; mouse button?
	  ;INVOKE MessageBox, hWnd, ADDR PopupText,ADDR PopupTitle, MB_OK
		.IF startPage
		  mov byte ptr [startPage], FALSE 
		  mov newGame, 1
		  jmp WinProcExit
		.ENDIF
		.IF successPage
		  mov byte ptr [successPage], FALSE
		  mov newGame, 1
		  jmp WinProcExit
		 .ENDIF
		.IF failPage
		  mov byte ptr [failPage], FALSE
		  mov byte ptr [startPage], TRUE
		  mov newGame, 1
		 ; INVOKE GetClientRect, hWnd, addr clientRect;
		 ; INVOKE UpdateWindow, hWnd;
		 ; INVOKE RedrawWindow,hWnd, addr clientRect, NULL, RDW_UPDATENOW;
		  jmp WinProcExit
		 .ENDIF

		.IF isLeftClick==0 
		  mov isLeftClick,1
		  invoke SetTimer,hWnd,0, 50 ,NULL
		  jmp Done
		.ELSEIF isLeftClick==1 
		  ;invoke KillTimer,hWnd,0
		  ;invoke SetTimer,hWnd,1,500,NULL
		  mov hookismoving, 1
		  mov isLeftClick,2
		  jmp Done
		.ELSEIF isLeftClick==2
		   ;mov isLeftClick,0
		  jmp Done
		.ENDIF
		Done:jmp WinProcExit
	.ELSEIF eax ==WM_KEYDOWN
	    .IF wParam == VK_4
		 .IF bombNum > 0
		  .IF hitItem!=100
			.IF hitItem==0
			INVOKE BombedOut, 0
			.ELSEIF hitItem==1
			INVOKE BombedOut, 1
			.ELSEIF hitItem==2
			INVOKE BombedOut, 2
			.ELSEIF hitItem==3
			INVOKE BombedOut, 3
			.ELSEIF hitItem==4
			INVOKE BombedOut, 4
			.ELSEIF hitItem==5
			INVOKE BombedOut, 5
			.ELSEIF hitItem==6
			INVOKE BombedOut, 6
			.ELSEIF hitItem==7
			INVOKE BombedOut, 7
			.ELSEIF hitItem==8
			INVOKE BombedOut, 8
			.ELSEIF hitItem==9
			INVOKE BombedOut, 9
			.ENDIF
			mov hitItem,100
		  .ENDIF
		 .ENDIF
		.ELSEIF wParam==VK_1
		 .IF stonevNum>0
		  mov stone2gold,3
		  DEC stonevNum
		 .ENDIF
		.ELSEIF wParam==VK_2
		 .IF strengthNum>0
		   mov strength,2
		   DEC strengthNum
		 .ENDIF
		.ELSEIF wParam==VK_3
		 .IF speedNum>0
		     mov humanspeed,2
		     DEC speedNum
		 .ENDIF
		.ELSEIF wParam==VK_CONTROL
		 .IF startPage
			INVOKE MessageBox, hWnd, ADDR readmeText,ADDR readmeTitle, MB_OK
		 .ENDIF
		.ENDIF
	 jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?

	  INVOKE LoadIcon, hInstance, 114
	  mov starticon,eax
	  INVOKE LoadIcon, hInstance, 106
	  mov diggericon,eax
	  INVOKE LoadIcon, hInstance, 105
	  mov bagicon1,eax
	  INVOKE LoadIcon, hInstance, 105
	  mov bagicon2,eax
	  INVOKE LoadIcon, hInstance, 105
	  mov bagicon3,eax
	  INVOKE LoadIcon, hInstance, 108
	  mov stoneicon1,eax
	  INVOKE LoadIcon, hInstance, 108
	  mov stoneicon2,eax
	  INVOKE LoadIcon, hInstance, 108
	  mov stoneicon3,eax
	  INVOKE LoadIcon, hInstance, 108
	  mov stoneicon4,eax
	  INVOKE LoadIcon, hInstance, 108
	  mov stoneicon5,eax
	  INVOKE LoadIcon, hInstance, 107
	  mov goldicon1,eax
	  INVOKE LoadIcon, hInstance, 107
	  mov goldicon2,eax
	  INVOKE LoadIcon, hInstance, 129
	  mov diamondicon,eax
	  INVOKE LoadIcon, hInstance, 130
	  mov tnticon,eax

	  INVOKE LoadIcon, hInstance, 109
	  mov hookicon,eax
	  INVOKE LoadIcon, hInstance, 115
	  mov lineicon,eax
	  invoke LoadIcon, hInstance, 111
	  mov bgicon,eax
	  mov hookPosX,100
	  mov hookPosY,181

	  INVOKE LoadIcon, hInstance, 116
	  mov bombstack,eax
	  INVOKE LoadIcon, hInstance, 117
	  mov powermed,eax
	  INVOKE LoadIcon, hInstance, 118
	  mov speedmed,eax
	  INVOKE LoadIcon, hInstance, 119
	  mov stonebook,eax

	  INVOKE LoadBitmap, hInstance, 120
	  mov startbmp, eax
	  INVOKE LoadBitmap, hInstance, 110
	  mov bgbmp, eax
	  INVOKE LoadBitmap, hInstance, 125
	  mov successbmp, eax
	  INVOKE LoadBitmap, hInstance, 128
	  mov failbmp, eax

	  jmp WinProcExit
	.ELSEIF eax == WM_CLOSE		; close window?

	  INVOKE PostQuitMessage,0
	  jmp WinProcExit
	.ELSEIF eax == WM_TIMER
	  .IF newGame == 1
	  mov gametimeLeft,1200 ;debug 1200
	  mov newGame, 0
	  mov byte ptr [firstDraw], TRUE 
	  .ENDIF




	  .IF (successPage||failPage||startPage) 
	  jmp WinProcExit
	  .ENDIF
	  dec gametimeLeft


	  .IF isLeftClick==1
	  cmp hookPosX,100
	  jl LessThan100
	  jg nextcompare
      LessThan100:
        mov range,FALSE

	  nextcompare:
	  cmp hookPosX, 1500
	  jl Done1
      jg GreaterThan1000
	  GreaterThan1000:
        mov range,TRUE

	  jmp Done1

	  .ELSEIF isLeftClick!=1
	  
	  cmp hookPosY,180
	  jl LessThan180
	  jg nextcompare1
      LessThan180:
	    mov hookPosY,181
        mov range2,2
		
	  nextcompare1:
	INVOKE IsHit
	  cmp eax, 100
	  je nextcompare2
	  mov hitItem, eax
	  .IF hitItem == 12 || hitItem == 13
		;mov isLeftClick, 0
		;mov range2, 2
		jmp fail
	  .ENDIF	
	  mov range2, 1
	  jmp Done2
	  nextcompare2:
	  cmp hookPosY, 700
	  jl Done2
      jg GreaterThan700
	  GreaterThan700:
        mov range2,1
	  jmp Done2
      .ENDIF
	Done1:
	   .IF range==0
	     mov eax,8
		 mul humanspeed
	     add hookPosX, eax
	   .ELSEIF range==1
	     mov eax,8 
		 mul humanspeed
	     sub hookPosX, eax
	   .ENDIF
	   mov eax, stageIndex
	   imul eax, 400
	   add eax, 600
	   mov stageTarget, eax
	  .IF totalValue >= eax ;debug
		   mov byte ptr [successPage], TRUE
		   ;mov newGame, 1
		   mov byte ptr [firstDraw], TRUE 
		   mov totalValue, 0
		   mov itemLeft, 0
		   mov strength, 1
		   mov humanspeed, 1
		   mov isLeftClick, 0
		mov range2, 0
		   inc stageIndex
		  ;TODO ���Ƴɹ�����ҳ��
	  .ELSEIF gametimeLeft <= 1
	  fail:
		  mov byte ptr [failPage], TRUE
		  ;mov newGame, 1
		  mov byte ptr [firstDraw], TRUE 
		  mov gametimeLeft, 0
		  mov itemLeft, 0
		  mov strength, 1
		  mov humanspeed, 1
		  mov stageIndex, 1
		  mov isLeftClick, 0
		  mov range2, 0
		  mov hookismoving, 0
		  ;TODO ����ʧ�ܽ���ҳ��
	  .ENDIF
	   INVOKE InvalidateRect,hWnd,NULL,TRUE
	   jmp WinProcExit
	Done2:
	   .IF hookismoving == 1
	   .IF range2==0	   
	   add hookPosY, 6
	   .ELSEIF range2==1
	   ; �������������ٶ�
			.IF hitItem == 100
			    mov ax,15
				mul strength
				sub hookPosY, eax
			.ELSE
				INVOKE getSpeed, hitItem
				mul strength
				sub hookPosY, eax
			.ENDIF
	   .ELSEIF range2==2
	     mov range2,0
		 mov hitItem, 100
	     mov isLeftClick,0
		 mov hookismoving, 0
	     ;invoke KillTimer,hWnd,0
	   .ENDIF
	   .ENDIF
	   mov eax, stageIndex
	   imul eax, 400
	   add eax, 600
	   mov stageTarget, eax
	   .IF totalValue >= eax
		   mov byte ptr [successPage], TRUE
		   ;mov newGame, 1
		   mov byte ptr [firstDraw], TRUE 
		   mov totalValue, 0
		   mov itemLeft, 0
		   mov strength, 1
		   mov humanspeed, 1
		   mov isLeftClick, 0
			mov range2, 0
		   inc stageIndex
		  ;TODO ���Ƴɹ�����ҳ��
	  .ELSEIF gametimeLeft <= 1
		  mov byte ptr [failPage], TRUE
		  mov byte ptr [firstDraw], TRUE 
		  ;mov newGame, 1
		  mov gametimeLeft, 0
		  mov itemLeft, 0
		  mov strength, 1
		  mov humanspeed, 1
		  mov stageIndex, 1
		  mov isLeftClick, 0
		  mov range2, 0
		  mov hookismoving, 0
		  ;TODO ����ʧ�ܽ���ҳ��
	  .ENDIF
	   INVOKE InvalidateRect,hWnd,NULL,TRUE

	   jmp WinProcExit
	.ELSEIF eax == WM_PAINT		; draw picture?
		.IF itemLeft == 0
		mov byte ptr [firstDraw], TRUE 
		.ENDIF

		

		INVOKE BeginPaint, hWnd, addr ps

		INVOKE GetClientRect, hWnd, addr clientRect;
		;INVOKE SetTextColor, ps.hdc, 0FF0000h

		.IF startPage
		;INVOKE DrawIconEx, ps.hdc, 0, 0, starticon, 1800, 900, 0, NULL, DI_NORMAL
		;INVOKE loadSound,addr modelMusicstartgame,addr modelMusicstartgameP
		;INVOKE playSound,modelMusicstartgameP,0
		INVOKE CreateCompatibleDC, ps.hdc
		mov cpthdc,eax
		INVOKE SelectObject, cpthdc,startbmp
		INVOKE sndPlaySound,122, SND_ASYNC or SND_RESOURCE
		INVOKE StretchBlt,ps.hdc, 0, 0, 1800, 900,cpthdc, 0, 0, 1800,900,SRCCOPY;
		INVOKE DeleteDC, cpthdc
		jmp quitDraw
		.ENDIF

		.IF successPage
		;INVOKE DrawIconEx, ps.hdc, 0, 0, starticon, 1800, 900, 0, NULL, DI_NORMAL
		;INVOKE loadSound,addr modelMusicstartgame,addr modelMusicstartgameP
		;INVOKE playSound,modelMusicstartgameP,0
		INVOKE CreateCompatibleDC, ps.hdc
		mov cpthdc,eax
		INVOKE SelectObject, cpthdc,successbmp
		INVOKE sndPlaySound,122, SND_ASYNC or SND_RESOURCE
		INVOKE StretchBlt,ps.hdc, 0, 0, 1800, 900,cpthdc, 0, 0, 1800,900,SRCCOPY;
		INVOKE DeleteDC, cpthdc
		jmp quitDraw
		.ENDIF

		.IF failPage
		;INVOKE DrawIconEx, ps.hdc, 0, 0, starticon, 1800, 900, 0, NULL, DI_NORMAL
		;INVOKE loadSound,addr modelMusicstartgame,addr modelMusicstartgameP
		;INVOKE playSound,modelMusicstartgameP,0
		INVOKE CreateCompatibleDC, ps.hdc
		mov cpthdc,eax
		INVOKE SelectObject, cpthdc,failbmp
		INVOKE sndPlaySound,126, SND_ASYNC or SND_RESOURCE
		INVOKE StretchBlt,ps.hdc, 0, 0, 1800, 900,cpthdc, 0, 0, 1800,900,SRCCOPY;
		INVOKE DeleteDC, cpthdc
		jmp quitDraw
		.ENDIF

		;INVOKE loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
		;INVOKE playSound,modelMusicset_xpxP,0
		;INVOKE DrawIconEx, ps.hdc, 0, 0, bgicon, 1800, 900, 0, NULL, DI_NORMAL
		INVOKE sndPlaySound,122, SND_ASYNC or SND_RESOURCE
		INVOKE DrawIconEx, ps.hdc, 0, 0, bgicon, 1800, 900, 0, NULL, DI_NORMAL
		;INVOKE CreateCompatibleDC, ps.hdc
		;mov cpthdc,eax
		;INVOKE SelectObject, cpthdc,bgbmp
		;INVOKE StretchBlt,ps.hdc, 0, 0, 1800, 900,cpthdc, 0, 0, 1800,900,SRCCOPY;
		;INVOKE BitBlt, ps.hdc, 0, 0, 1800, 900, cpthdc, 0, 0, SRCCOPY;
		mov edx,0
		mov eax,gametimeLeft
		mov ebx,20
		div ebx
		mov gametimeShow, eax

		INVOKE wsprintf,offset PointBuffer,offset PointText,stageIndex,totalValue, gametimeShow,stonevNum,strengthNum,speedNum,bombNum
		INVOKE DrawTextEx, ps.hdc, addr PointBuffer, -1, addr clientRect, DT_CENTER, NULL 

		INVOKE DrawIconEx, ps.hdc, 920, 0, stonebook, 30, 30, 0, NULL, DI_NORMAL
		INVOKE DrawIconEx, ps.hdc, 1000, 0, powermed, 30, 30, 0, NULL, DI_NORMAL
		INVOKE DrawIconEx, ps.hdc, 1080, 0, speedmed, 30, 30, 0, NULL, DI_NORMAL
		INVOKE DrawIconEx, ps.hdc, 1160, 0, bombstack, 30, 30, 0, NULL, DI_NORMAL
		
			.IF firstDraw 
				mov eax, 100
				mov hookPosX, eax
				mov eax, 181
				mov hookPosY, eax
			.ENDIF
			INVOKE DrawIconEx, ps.hdc, hookPosX, 60, diggericon, 100, 100, 0, NULL, DI_NORMAL

			mov ebx, 160
			mov hookup, ebx
			hookLoop:
				mov ebx, hookup
				cmp ebx, hookPosY
				jg endhookLoop
				INVOKE DrawIconEx, ps.hdc, hookPosX, hookup, lineicon, hookHeight, hookWidth, 0, NULL, DI_NORMAL
				mov ebx, hookup
				add ebx, 40
				mov hookup, ebx
				jmp hookLoop
			endhookLoop:
			INVOKE DrawIconEx, ps.hdc, hookPosX, hookPosY, hookicon, hookHeight, hookWidth, 0, NULL, DI_NORMAL

			.IF firstDraw 
					push 0
					call crt_time
					add esp, 4
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx

					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddBagItem, randposx1, randposy1, 50
			.ENDIF

			INVOKE getPosX, 0
			mov tempPosX, eax
			INVOKE getPosY, 0
			mov tempPosY, eax


			mov edi, OFFSET Items
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=0
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, bagicon1, 50, 50, 0, NULL, DI_NORMAL
				.ELSE
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, bagicon1, 50, 50, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 0
					INVOKE RandomBag
					.ENDIF
				.ENDIF
			.ENDIF	

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��		
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddBagItem, randposx1, randposy1, 50
			.ENDIF

			INVOKE getPosX, 1
			mov tempPosX, eax
			INVOKE getPosY, 1
			mov tempPosY, eax


			mov edi, OFFSET Items
			add edi, 28
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=1
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, bagicon2, 50, 50, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, bagicon2, 50, 50, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 1
					INVOKE RandomBag
					.ENDIF
				.ENDIF	
			.ENDIF

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddBagItem, randposx1, randposy1, 50
			.ENDIF

			INVOKE getPosX, 2
			mov tempPosX, eax
			INVOKE getPosY, 2
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 56
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=2
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, bagicon3, 50, 50, 0, NULL, DI_NORMAL
				.ELSE
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, bagicon3, 50, 50, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 2
					INVOKE RandomBag
					.ENDIF
				.ENDIF
			.ENDIF	

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddStoneItem, randposx1, randposy1, 50
				.ENDIF

			INVOKE getPosX, 3
			mov tempPosX, eax
			INVOKE getPosY, 3
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 84
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=3
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, stoneicon1, 50, 50, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, stoneicon1, 50, 50, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 3
					.ENDIF
				.ENDIF	
			.ENDIF	

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					invoke AddStoneItem, randposx1, randposy1, 50
			.ENDIF

			INVOKE getPosX, 4
			mov tempPosX, eax
			INVOKE getPosY, 4
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 112
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=4
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, stoneicon2, 50, 50, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, stoneicon2, 50, 50, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 4
					.ENDIF
				.ENDIF	
			.ENDIF

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��		
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddStoneItem, randposx1, randposy1, 50
			.ENDIF

			INVOKE getPosX, 5
			mov tempPosX, eax
			INVOKE getPosY, 5
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 140
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=5
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, stoneicon3, 50, 50, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, stoneicon3, 50, 50, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 5
					.ENDIF
				.ENDIF	
			.ENDIF

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��		
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddStoneItem, randposx1, randposy1, 100
			.ENDIF

			INVOKE getPosX, 6
			mov tempPosX, eax
			INVOKE getPosY, 6
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 168
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=6
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, stoneicon4, 100, 100, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, stoneicon4, 100, 100, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 6
					.ENDIF
				.ENDIF	
			.ENDIF

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��		
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddStoneItem, randposx1, randposy1, 150
			.ENDIF

			INVOKE getPosX, 7
			mov tempPosX, eax
			INVOKE getPosY, 7
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 196
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=7
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, stoneicon1, 150, 150, 0, NULL, DI_NORMAL
				.ELSE
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, stoneicon1, 150, 150, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 7
					.ENDIF
				.ENDIF	
			.ENDIF	

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddGoldItem, randposx1, randposy1, 50
			.ENDIF

			INVOKE getPosX, 8
			mov tempPosX, eax
			INVOKE getPosY, 8
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 224
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=8
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, goldicon1, 50, 50, 0, NULL, DI_NORMAL
				.ELSE
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, goldicon1, 50, 50, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 8
					.ENDIF
				.ENDIF	
			.ENDIF	

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddGoldItem, randposx1, randposy1, 100
			.ENDIF

			INVOKE getPosX, 9
			mov tempPosX, eax
			INVOKE getPosY, 9
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 252
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=9
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, goldicon2, 100, 100, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, goldicon2, 100, 100, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 9
					.ENDIF
				.ENDIF	
			.ENDIF	

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddDiamondItem, randposx1, randposy1, 30
			.ENDIF

			INVOKE getPosX, 10
			mov tempPosX, eax
			INVOKE getPosY, 10
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 280
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=10
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, diamondicon, 30, 30, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, diamondicon, 30, 30, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger, 10
					.ENDIF
				.ENDIF	
			.ENDIF	

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddDiamondItem, randposx1, randposy1, 30
			.ENDIF

			INVOKE getPosX, 11
			mov tempPosX, eax
			INVOKE getPosY, 11
			mov tempPosY, eax

			mov edi, OFFSET Items
			add edi, 308
			mov ebx, [edi]
			.IF ebx == 1
				.IF hitItem!=11
				INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, diamondicon, 30, 30, 0, NULL, DI_NORMAL
				.ELSE	
				mov ebx, hookPosY
				add ebx, 40
				INVOKE DrawIconEx, ps.hdc, tempPosX, ebx, diamondicon, 30, 30, 0, NULL, DI_NORMAL
					.if ebx <= 220
					INVOKE ExistNoLonger,11
					.ENDIF
				.ENDIF	
			.ENDIF	


			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddTNTItem, randposx1, randposy1, 80
			.ENDIF

			INVOKE getPosX, 12
			mov tempPosX, eax
			INVOKE getPosY, 12
			mov tempPosY, eax

			INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, tnticon, 80, 80, 0, NULL, DI_NORMAL

			.IF firstDraw 
					mov eax, randposx1
					push eax
					call crt_srand
					add esp, 4

					invoke crt_rand; �����������������eax��
					mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
					mov ebx, 1300;
					div ebx; ����0~9����edx��	
					add edx, 100
					mov randposx1, edx


					invoke crt_rand
					mov edx, 0
					mov ebx, 450
					div ebx
					add edx, 250
					mov randposy1, edx
					INVOKE AddTNTItem, randposx1, randposy1, 80
			.ENDIF

			INVOKE getPosX, 13
			mov tempPosX, eax
			INVOKE getPosY, 13
			mov tempPosY, eax

			INVOKE DrawIconEx, ps.hdc, tempPosX, tempPosY, tnticon, 80, 80, 0, NULL, DI_NORMAL
			

	quitDraw:
		
		mov byte ptr [firstDraw], FALSE 
		INVOKE EndPaint, hWnd, ADDR ps
    
		mov byte ptr [isDrawingIcon], FALSE 


		jmp WinProcExit
	.ELSEIF eax == WM_ERASEBKGND
	    jmp WinProcExit
	.ELSE		; other message?
	  INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
	  jmp WinProcExit
	.ENDIF


WinProcExit:
	ret
WinProc ENDP

;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

END WinMain