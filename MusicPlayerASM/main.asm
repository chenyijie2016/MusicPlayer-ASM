.386

.model flat,stdcall
option casemap:none
.stack 4096

;     include files
include windows.inc
include masm32.inc
include gdi32.inc
include user32.inc
include kernel32.inc
include Comctl32.inc
include comdlg32.inc
include shell32.inc
include oleaut32.inc
include msvcrt.inc
include winmm.inc
;include C:\masm32\macros\macros.asm

;     libraries
includelib masm32.lib
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib Comctl32.lib
includelib comdlg32.lib
includelib shell32.lib
includelib oleaut32.lib
includelib msvcrt.lib
includelib winmm.lib

WinMain proto:DWORD, :DWORD, :DWORD, :DWORD
InitInstance proto:HINSTANCE,:DWORD




.data
szWindowClass db "MusicPlayer",0
szTitle db "MusicPlayer",0
AppName db "MusicPlayer", 0
szTextFileName db "FileName",0
szTextFileSize db "FileSize",0

fontname db 'C', 0, 'o', 0, 'n', 0, 's', 0, 'o', 0, 'l', 0, 'a', 0, 's', 0, 0, 0 ; Consolas
text_button db "button",0
text_play db "play",0
text_opendir db "Open Directory",0
PROGRESSCLASS db "msctls_progress32",0
LISTVIEWCLASS db "SysListView32",0
; 控件的全局ID
IDC_PLAYBTN HMENU 205
IDC_LISTVIEW HMENU 206
IDC_OPENDIRBTN HMENU 207
IDC_EDITCHILD HMENU 208
IDC_CURRENTPLAYTIME HMENU 209
IDC_TOTALPLAYTIME HMENU 210
IDC_STOPBTN HMENU 211
IDC_PROGRESSBAR HMENU 212

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ? 

; 控件的Handle
hFont HFONT ?
hPlayBtn HWND ?
hwndPB HWND ?
hListView HWND ?
hOpenDirBtn HWND ?
hwndEdit HWND ?
hStopBtn HWND ?
hTotalPlayTime HWND ?
hCurrentPlayTime HWND ?

DIR WCHAR 1024 DUP(?)
Info WCHAR 1024 DUP(?)


.code
start:
	invoke GetModuleHandle, NULL
	mov hInstance, eax
	invoke GetCommandLine
	mov CommandLine, eax
	invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess, eax

;----------------------------------
;注册窗口类
;
MyRegisterClass proc hInst:HINSTANCE
;----------------------------------
	LOCAL wcex: WNDCLASSEXW
	mov wcex.cbSize, sizeof WNDCLASSEX
	mov wcex.style, CS_HREDRAW or CS_VREDRAW
	mov wcex.lpfnWndProc, OFFSET WndProc 
	mov wcex.cbClsExtra, NULL
	mov wcex.cbWndExtra, NULL
	push hInst
	pop wcex.hInstance
	mov wcex.hbrBackground, COLOR_WINDOW + 1
	mov wcex.lpszMenuName, NULL
	mov wcex.lpszClassName ,offset szWindowClass
	invoke LoadIcon, NULL, IDI_APPLICATION
	mov wcex.hIcon, eax
	mov wcex.hIconSm, eax
	invoke LoadCursor, NULL, IDC_ARROW
	mov wcex.hCursor, eax
	invoke RegisterClassEx, addr wcex
	ret
MyRegisterClass endp

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine: LPSTR, CmdShow:DWORD
	local msg :MSG


	invoke MyRegisterClass, hInst
	invoke InitInstance, hInst, CmdShow

	; 主消息循环
	.while TRUE
		invoke GetMessage, addr msg, NULL, 0, 0
		.break .if (!eax)
		invoke TranslateMessage, addr msg
		invoke DispatchMessage, addr msg
	.endw

	mov eax, msg.wParam
	ret

WinMain endp

;---------------------
;函数: InitInstance(HINSTANCE, int)
;目标: 保存实例句柄并创建主窗口
;注释:
;
;        在此函数中，我们在全局变量中保存实例句柄并
;        创建和显示主程序窗口。
InitInstance proc hInst: HINSTANCE, CmdShow :DWORD
;------------------------
	local hwnd:HWND
	invoke CreateWindowEx, NULL, addr szWindowClass, addr szTitle, 
		WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 500, 600, 
		NULL, NULL, hInst, NULL
	mov hwnd, eax

	.if (!eax)
		ret
	.endif
	
	invoke ShowWindow, hwnd, SW_SHOWNORMAL
	invoke UpdateWindow, hwnd

	ret
InitInstance endp 

;-----------------------------------------
; 创建控件
;
CreateWindowControl proc uses eax hWnd:HWND
;------------------------------------------
	local lvc:LVCOLUMN
	; 创建字体
	invoke CreateFontW , -15 , -8, 0, 0, 400,
		FALSE, FALSE, FALSE, DEFAULT_CHARSET,
		OUT_CHARACTER_PRECIS,CLIP_CHARACTER_PRECIS,
		DEFAULT_QUALITY,FF_DONTCARE,
		offset fontname
	mov hFont, eax

	;创建play按钮
	invoke CreateWindowEx, 0, offset text_button, offset text_play, 
		WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON,
		0, 0, 0, 0,
		hWnd, IDC_PLAYBTN, hInstance, NULL
	mov hPlayBtn, eax

	invoke SendMessage, hPlayBtn, WM_SETFONT, hFont, NULL
	; 创建进度条
	invoke CreateWindowEx, 0, offset PROGRESSCLASS, NULL ,
		WS_VISIBLE or WS_CHILD or PBS_SMOOTH,
		0, 0, 0, 0,
		hWnd,
		IDC_PROGRESSBAR,
		hInstance,
		NULL
	mov hwndPB, eax

	;创建listview
	invoke CreateWindowEx, 0, offset LISTVIEWCLASS, NULL ,
		WS_VISIBLE or WS_CHILD or LVS_REPORT or LVS_EDITLABELS,
		0, 0, 0, 0,
		hWnd,
		IDC_LISTVIEW,
		hInstance,
		NULL
	mov hListView, eax
	;mov lvc.mask,  01111b
	mov lvc._mask, 1111b
	mov lvc.iSubItem, 0
	mov lvc.pszText, offset szTextFileName
	mov lvc._cx, 350

	invoke SendMessage, hListView, LVM_INSERTCOLUMN, 0, addr lvc
	mov lvc.iSubItem, 1 
	mov lvc.pszText, offset szTextFileSize
	mov lvc._cx, 100
	invoke SendMessage, hListView, LVM_INSERTCOLUMN, 1, addr lvc
	

	;创建打开文件按钮
	invoke CreateWindowEx, 0, offset text_button, offset text_opendir, 
		WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON,
		0, 0, 0, 0,
		hWnd, IDC_OPENDIRBTN, hInstance, NULL
	mov hOpenDirBtn, eax
	ret
CreateWindowControl endp

;-----------------------------------------
; 调整控件位置
;
ReSizeWindowControl proc uses eax ebx hWnd:HWND
;-----------------------------------------
	local rc:RECT
	local current_width:DWORD
	local current_height:DWORD
	local middle:DWORD
	local _bottom

	local pb_left:DWORD
	local pb_bottom:DWORD
	local pb_width:DWORD

	local lv_left:DWORD
	local lv_top:DWORD
	local lv_width:DWORD
	local lv_height:DWORD


	; 确定 play 按钮的位置
	mov eax, 0 
	invoke GetClientRect, hWnd, addr rc
	mov ebx, rc.right
	sub ebx, rc.left
	mov current_width, ebx ; current_width =  rc.right - rc.left
	mov eax, current_width
	mov ebx, 2
	mov dx, 0
	div ebx
	mov middle, eax ;middle = current_width /2
	sub middle, 30

	mov ebx, rc.bottom
	sub ebx, rc.top
	mov current_height, ebx
	mov eax, rc.bottom
	mov _bottom, eax
	sub _bottom, 40


	invoke MoveWindow, hPlayBtn, middle, _bottom, 60, 30, TRUE

	; 确定进度条的位置
	mov eax, rc.left
	add eax, 80
	mov pb_left, eax
	mov eax, rc.bottom
	sub eax, 70
	mov pb_bottom,eax
	mov eax, current_width
	sub eax, 160
	mov pb_width, eax

	invoke MoveWindow, hwndPB, pb_left, pb_bottom, pb_width, 15, TRUE

	;确定ListView 的位置
	mov eax, rc.left
	add eax, 20
	mov lv_left, eax
	mov eax, rc.top
	add eax, 10
	mov lv_top, eax
	mov eax, current_width
	sub eax, 40
	mov lv_width, eax
	mov eax, current_height
	sub eax, 250
	mov lv_height, eax

	invoke MoveWindow, hListView, lv_left, lv_top, lv_width, lv_height, TRUE
	ret
ReSizeWindowControl endp



WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
	LOCAL ps:PAINTSTRUCT 

	.if uMsg == WM_DESTROY
		invoke PostQuitMessage,NULL 
	.elseif uMsg == WM_PAINT
		invoke BeginPaint, hWnd, ADDR ps 
		invoke EndPaint, hWnd, ADDR ps 

	; 创建控件
	.elseif uMsg == WM_CREATE
		invoke InitCommonControls
		invoke CreateWindowControl, hWnd
	
	; 窗口变化大小
	.elseif uMsg == WM_SIZE
		invoke ReSizeWindowControl, hWnd
	.else
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
	.endif
	ret
WndProc endp

end start

