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
include shfolder.inc
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
FileInfo struct
	filename WCHAR 256 DUP(?)
	filesize LARGE_INTEGER <>
FileInfo ends

Files FileInfo 1024 DUP(<>)


szWindowClass db "MusicPlayer",0
szTitle db "MusicPlayer",0
AppName db "MusicPlayer", 0
szTextFileName db "FileName",0
szTextFileSize db "FileSize",0

fontname db 'C', 0, 'o', 0, 'n', 0, 's', 0, 'o', 0, 'l', 0, 'a', 0, 's', 0, 0, 0 ; Consolas
text_button db "button", 0
text_play db "play", 0
text_edit db "edit",0
text_opendir db "Open Directory", 0
text_browse_folder db "Browse folder", 0



find_dir_fmt db '%', 0, 's', 0, '\', '*',0, 0, 0; "%s\\*"
s_fmt db '%',0,'s',0, 0, 0 ;"%s"
d_fmt db '%', 0, 'd', 0, 0, 0
PROGRESSCLASS db "msctls_progress32",0
LISTVIEWCLASS db "SysListView32",0

text_static db "static",0
text_0000 db "00:00",0

; �ؼ���ȫ��ID
IDC_PLAYBTN HMENU 205
IDC_LISTVIEW HMENU 206
IDC_OPENDIRBTN HMENU 207
IDC_EDIT HMENU 208
IDC_CURRENTPLAYTIME HMENU 209
IDC_TOTALPLAYTIME HMENU 210
IDC_STOPBTN HMENU 211
IDC_PROGRESSBAR HMENU 212

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ? 

; �ؼ���Handle
hFont HFONT ?
hPlayBtn HWND ?
hwndPB HWND ?
hListView HWND ?
hOpenDirBtn HWND ?
hwndEdit HWND ?
hStopBtn HWND ?
hTotalPlayTime HWND ?
hCurrentPlayTime HWND ?

DIR WCHAR 1024 DUP(0)
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
;ע�ᴰ����
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

	; ����Ϣѭ��
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
;����: InitInstance(HINSTANCE, int)
;Ŀ��: ����ʵ�����������������
;ע��:
;
;        �ڴ˺����У�������ȫ�ֱ����б���ʵ�������
;        ��������ʾ�����򴰿ڡ�
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
; �����ؼ�
;
CreateWindowControl proc uses eax hWnd:HWND
;------------------------------------------
	local lvc:LVCOLUMN
	; ��������
	invoke CreateFontW , -15 , -8, 0, 0, 400,
		FALSE, FALSE, FALSE, DEFAULT_CHARSET,
		OUT_CHARACTER_PRECIS,CLIP_CHARACTER_PRECIS,
		DEFAULT_QUALITY,FF_DONTCARE,
		offset fontname
	mov hFont, eax

	;����play��ť
	invoke CreateWindowEx, 0, offset text_button, offset text_play, 
		WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON,
		0, 0, 0, 0,
		hWnd, IDC_PLAYBTN, hInstance, NULL
	mov hPlayBtn, eax

	invoke SendMessage, hPlayBtn, WM_SETFONT, hFont, NULL
	; ����������
	invoke CreateWindowEx, 0, offset PROGRESSCLASS, NULL ,
		WS_VISIBLE or WS_CHILD or PBS_SMOOTH,
		0, 0, 0, 0,
		hWnd,
		IDC_PROGRESSBAR,
		hInstance,
		NULL
	mov hwndPB, eax

	;����listview
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
	

	;�������ļ���ť
	invoke CreateWindowEx, 0, offset text_button, offset text_opendir, 
		WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON,
		0, 0, 0, 0,
		hWnd, IDC_OPENDIRBTN, hInstance, NULL
	mov hOpenDirBtn, eax
	invoke SendMessage, hOpenDirBtn, WM_SETFONT, hFont, NULL



	; �����༭��
	invoke CreateWindowEx, 0, offset text_edit, NULL,
		WS_CHILD or WS_VISIBLE or ES_LEFT or ES_MULTILINE or \
		ES_AUTOVSCROLL or ES_READONLY,
		0, 0, 0, 0, 
		hWnd,IDC_EDIT,hInstance, NULL
	mov hwndEdit, eax
	invoke SendMessage, hwndEdit, WM_SETFONT, hFont, NULL

	; ��������ʱ���ı���

	invoke CreateWindowEx, 0, offset text_static, offset text_0000,
		WS_CHILD or WS_VISIBLE or SS_RIGHT,
		0, 0, 0, 0,
		hWnd, IDC_CURRENTPLAYTIME, hInstance, NULL
	mov hCurrentPlayTime, eax
	invoke SendMessage, hCurrentPlayTime, WM_SETFONT, hFont, NULL

	invoke CreateWindowEx, 0, offset text_static, offset text_0000,
		WS_CHILD or WS_VISIBLE or SS_LEFT,
		0, 0, 0, 0,
		hWnd, IDC_TOTALPLAYTIME, hInstance, NULL
	mov hTotalPlayTime, eax
	invoke SendMessage, hTotalPlayTime, WM_SETFONT, hFont, NULL




	ret
CreateWindowControl endp

;-----------------------------------------
; �����ؼ�λ��
;
ReSizeWindowControl proc uses eax ebx hWnd:HWND
;-----------------------------------------
	local rc:RECT
	local current_width:DWORD
	local current_height:DWORD
	local middle:DWORD
	local playBtn_bottom:DWORD

	local pb_left:DWORD
	local pb_bottom:DWORD
	local pb_width:DWORD

	local lv_left:DWORD
	local lv_top:DWORD
	local lv_width:DWORD
	local lv_height:DWORD

	local pl_time_left:DWORD

	local edit_top:DWORD

	; ȷ�� play ��ť��λ��
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
	mov playBtn_bottom, eax
	sub playBtn_bottom, 40


	invoke MoveWindow, hPlayBtn, middle, playBtn_bottom, 60, 30, TRUE

	; ȷ����������λ��
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

	;ȷ��ListView ��λ��
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

	; ȷ�����ļ��а�ťλ��

	invoke MoveWindow, hOpenDirBtn, lv_left, playBtn_bottom, 120, 30, TRUE

	; ȷ������ʱ����ʾλ��

	invoke MoveWindow, hCurrentPlayTime, lv_left, pb_bottom, 55, 15, TRUE

	mov eax, rc.right
	sub eax, 75
	mov pl_time_left, eax
	invoke MoveWindow, hTotalPlayTime, pl_time_left, pb_bottom, 55, 15, TRUE


	mov eax, rc.bottom
	sub eax, 200
	mov edit_top, eax
	invoke MoveWindow, hwndEdit, lv_left, edit_top, lv_width, 60, TRUE

	ret
ReSizeWindowControl endp

;------------------------------
; ѡ��Ŀ¼
;
SelectDir proc hWnd:HWND
	local bInfo: BROWSEINFO
	local lpDlist: DWORD
	invoke RtlZeroMemory, addr bInfo, sizeof BROWSEINFO ;һ��Ҫ���ڴ���0������ᱨ��
	invoke GetForegroundWindow
	mov bInfo.hwndOwner, eax
	mov bInfo.lpszTitle, offset text_browse_folder
	mov bInfo.ulFlags, BIF_RETURNONLYFSDIRS or BIF_USENEWUI or BIF_UAHINT or BIF_NONEWFOLDERBUTTON ;/*�����½��ļ��а�ť*/
	invoke SHBrowseForFolder, addr bInfo
	mov lpDlist, eax

	cmp eax, 0 ; if lpDlist != NULL
	;jnz returnselectdir
	invoke SHGetPathFromIDList ,lpDlist, offset DIR
returnselectdir:	
	ret
SelectDir endp



FindFile proc
	local ffd: WIN32_FIND_DATA
	local hFind: HANDLE
	local FileCount: DWORD
	local lvI:LVITEMW
	local tempdir[260]:WCHAR
	invoke RtlZeroMemory, addr lvI, sizeof LVITEMW
	invoke RtlZeroMemory,addr ffd,sizeof WIN32_FIND_DATA
	mov lvI.pszText, LPSTR_TEXTCALLBACKW
	mov lvI._mask, LVIF_TEXT or LVIF_IMAGE or LVIF_STATE
	invoke wsprintfW, addr tempdir, offset find_dir_fmt, offset DIR

	invoke FindFirstFile, addr tempdir, addr ffd
	mov hFind, eax
	.if eax == -1
		ret ; error!
	.endif
	mov FileCount, 0

	invoke SendMessage, hwndEdit, WM_SETTEXT, 0, addr tempdir

	do_start:
		mov eax, ffd.dwFileAttributes
		and eax, FILE_ATTRIBUTE_DIRECTORY
		cmp eax, 0
		jnz do; if it is directory, jump to label 'do'

		
		mov eax, FileCount
		mov ebx, sizeof FileInfo
		mul ebx
		assume ebx:PTR FileInfo
		mov ebx, offset Files
		add ebx, eax
		invoke wsprintfW, addr [ebx].filename, offset s_fmt, addr ffd.cFileName

		mov eax, ffd.nFileSizeHigh
		mov [ebx].filesize.HighPart, eax
		mov eax, ffd.nFileSizeLow
		mov [ebx].filesize.LowPart, eax
		assume ebx:nothing
		inc FileCount
	do:
		invoke FindNextFileW, hFind, addr ffd
		cmp eax, 0
		jnz do_start



	invoke SendMessage, hListView, LVM_DELETEALLITEMS, 0, 0
	mov ecx, 0
	
	.while ecx < FileCount
		inc lvI.iItem
		push lvI.iItem
		pop lvI.lParam
		inc ecx
		push ecx
		invoke SendMessage, hListView, LVM_INSERTITEM, 0, addr lvI
		pop ecx
	.endw

	ret
FindFile endp

handleListViewNotify proc lParam:LPARAM
	mov edx, lParam
	assume edx:PTR NMHDR
		; TODO:
		; ����Ĵ��뻹��bug ϣ�����ս��
		.if [edx].code == LVN_GETDISPINFO
			assume edx:PTR NMLVDISPINFOW
			mov ebx, offset Files
			mov eax, sizeof FileInfo
			mul [edx].item.iItem
			add ebx, eax
			assume ebx:PTR FileInfo
			.if [edx].item.iSubItem == 0
				lea ecx, [ebx]
				mov [edx].item.pszText, ecx
			.elseif [edx].item.iSubItem == 1
				invoke wsprintfW, addr [edx].item.pszText, offset d_fmt, [ebx].filesize 
			.endif
		.endif

	assume ebx:nothing
	assume edx:nothing

	ret
handleListViewNotify endp



WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
	local ps:PAINTSTRUCT 
	local wmId:WORD
	.if uMsg == WM_DESTROY
		invoke PostQuitMessage,NULL 

	.elseif uMsg == WM_COMMAND
		mov eax, DWORD PTR [wParam]
		and eax, 0ffffh
		; mov wmId, ax
		.if eax == IDC_OPENDIRBTN
			invoke SelectDir, hWnd
			invoke FindFile
		.elseif eax == IDC_PLAYBTN
			
		.elseif eax == IDC_STOPBTN
			
		.endif

	.elseif uMsg == WM_PAINT
		invoke BeginPaint, hWnd, ADDR ps 
		invoke EndPaint, hWnd, ADDR ps 
	.elseif uMsg == WM_NOTIFY
		mov eax, DWORD PTR [wParam]
		and eax, 0ffffh
		.if eax == IDC_LISTVIEW
			 invoke handleListViewNotify, lParam;bug�����
		.endif

	; �����ؼ�
	.elseif uMsg == WM_CREATE
		invoke InitCommonControls
		invoke CreateWindowControl, hWnd
	
	; ���ڱ仯��С
	.elseif uMsg == WM_SIZE
		invoke ReSizeWindowControl, hWnd
	.else
		invoke DefWindowProc, hWnd, uMsg, wParam, lParam 
	.endif
	ret
WndProc endp

end start
