// Written in the D programming language.
/*
 * dmd 2.070.0 - 2.071.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module utils;

import org.eclipse.swt.all;
import org.eclipse.swt.internal.win32.OS;
import org.eclipse.swt.internal.win32.WINAPI;
import java.lang.all;

import std.conv;
import std.file;
import std.path;

import dlsbuffer;

// @@ -------------------------------------------------------------------------
// Utils

// std.ascii.newline
version (Windows) {
	enum isWindows = true;
	enum PathDelimiter = "\\";
} else {
	enum isWindows = false;
	enum PathDelimiter = "/";
}

// file operation.
void MakeDir(string path) {
    if (!path.exists()) {
        std.file.mkdirRecurse(path);
    }
}
void Rename(string from, string to) {
    if (to.exists()) {
        to.remove();
    }
    std.file.rename(from, to);
}
void Remove(string path) {
    if (path.exists()) {
        std.file.remove(path);
    }
}
void RmDir(string path) {
    if (path.exists()) {
        std.file.rmdirRecurse(path);
    }
}
// CopyFiletoDir
// return stat
// 0:copy success / 0 != not copyed
int CopyFiletoDir(string fromFile, string todir) {
	int stat = -1;
	if (fromFile.exists()) {
		if (!todir.exists()) {
			MakeDir(todir);
		}
		if (todir.isDir()) {
			string toFile = todir ~ PathDelimiter ~ baseName(fromFile);
			dlog("CopyFiletoDir:fromFile: ", fromFile);
			dlog("CopyFiletoDir:toFile  : ", toFile);
			// don't copy same file
			if (fromFile != toFile) {
				if (toFile.exists()) {
					RecycleBin(toFile);
				}
				string[] fromFiles = [ fromFile ];
				stat = SHFileOperationCopy(fromFiles, toFile);
				// std.file.copy(fromFile, toFile);
				dlog("copy done..");
			}
			else {
				dlog("do not copy...");
			}
		}
		// isFile
		//
	}
	else {
		throw new Exception("CopyFiletoDir Error. See " ~ __FILE__ ~ to!string(__LINE__));
	}
	return stat;
}
// @@--------------------------------------------------------------------------
//

StringT stringArrayToStringT(string[] array) {
	StringBuffer sb = new StringBuffer();
	foreach (v ; array) {
		sb.append(v);
		sb.append('\0');
	}
	return StrToTCHARs(0, sb.toString(), true);
}
StringT stringToStringT(string st) {
	StringBuffer sb = new StringBuffer();
	sb.append(st);
	sb.append('\0');
	return StrToTCHARs(0, sb.toString(), true);
}

int SHFileOperationCopy(string[] fromFiles, string toPath) {
	dlog("SHFileOperationCopy");
	dlog("fromFiles:");
	foreach(v; fromFiles) {
		dlog(v);
	}
	dlog("toPath: ", toPath);
	
	StringT frombuffer = stringArrayToStringT(fromFiles);
	StringT tobuffer = stringToStringT(toPath);
	
	SHFILEOPSTRUCT op;
	op.wFunc = FO_COPY;
	op.pFrom = frombuffer.ptr;
	op.pTo   = tobuffer.ptr;
	op.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION;
	int stat = SHFileOperation(&op);
	if (stat != 0) {
		string err = getLastErrorText();
		dlog("GetLastError: ", err);
	}
	return stat;
}

int SHFileOperationMove(string[] fromFiles, string toPath) {
	dlog("SHFileOperationMove");
	dlog("fromFiles:");
	foreach(v; fromFiles) {
		dlog(v);
	}
	dlog("toPath: ", toPath);
	
	StringT frombuffer = stringArrayToStringT(fromFiles);
	StringT tobuffer = stringToStringT(toPath);
	
	SHFILEOPSTRUCT op;
	op.wFunc = FO_MOVE;
	op.pFrom = frombuffer.ptr;
	op.pTo   = tobuffer.ptr;
	op.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION;
	int stat = SHFileOperation(&op);
	if (stat != 0) {
		string err = getLastErrorText();
		dlog("GetLastError: ", err);
	}
	return stat;
}

int SHFileOperationRename(string fromFile, string toFile) {
	dlog("SHFileOperationRename");
	dlog("fromFile: ", fromFile);
	dlog("toFile: ", toFile);
	
	StringT frombuffer = stringToStringT(fromFile);
	StringT tobuffer = stringToStringT(toFile);

	SHFILEOPSTRUCT op;
	op.wFunc = FO_RENAME;
	op.pFrom = frombuffer.ptr;
	op.pTo   = tobuffer.ptr;
	op.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION;
	int stat = SHFileOperation(&op);
	if (stat != 0) {
		string err = getLastErrorText();
		dlog("GetLastError: ", err);
	}
	return stat;
}


int SHFileOperationDelete(string[] files) {
	dlog("SHFileOperationDelete");
	
	StringT buffer = stringArrayToStringT(files);
	
	SHFILEOPSTRUCT op;
	op.wFunc = FO_DELETE;
	op.pFrom = buffer.ptr;
	op.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION;
	int stat = SHFileOperation(&op);
	if (stat != 0) {
		// https://msdn.microsoft.com/ja-jp/library/windows/desktop/bb762164%28v=vs.85%29.aspx
		dlog("GetLastError: ", getLastErrorText());
//		MessageBox.showError(getLastErrorText(), "Error");
	}
	return stat;
}


int RecycleBin(string file) {
	string[] rb = [ file ];
	return RecycleBin(rb);
}

int RecycleBin(string[] files) {
	dlog("RecycleBin");
	StringBuffer buff = new StringBuffer();
	foreach (v ; files) {
		buff.append(v);
		buff.append('\0');
	}
	
	StringT buffer = StrToTCHARs(0, buff.toString(), true);
	
	SHFILEOPSTRUCT op;
	op.wFunc = FO_DELETE;
	op.pFrom = buffer.ptr;
	// op.fFlags = FOF_ALLOWUNDO;
	op.fFlags = FOF_ALLOWUNDO + FOF_NOCONFIRMATION;
	int stat = SHFileOperation(&op);
	if (stat != 0) {
		// https://msdn.microsoft.com/ja-jp/library/windows/desktop/bb762164%28v=vs.85%29.aspx
		dlog("stat: ", stat);
		string err = getLastErrorText();
		dlog("GetLastError: ", err);
//		MessageBox.showError(getLastErrorText(), "Error");
	}
	return stat;
}

string getLastErrorText() {
	int error = OS.GetLastError();
	if (error is 0) {
		return "non-error: 0";
	}
	TCHAR* buffer = null;
	int dwFlags = OS.FORMAT_MESSAGE_ALLOCATE_BUFFER | OS.FORMAT_MESSAGE_FROM_SYSTEM | OS.FORMAT_MESSAGE_IGNORE_INSERTS;
	int length = OS.FormatMessage(dwFlags, null, error, OS.LANG_USER_DEFAULT, cast(TCHAR*)&buffer, 0, null);
	string errorNum = ("[GetLastError=") ~ .toHex(error) ~ "] ";
	if (length == 0) {
		return errorNum;
	}
	string buffer1 = .TCHARzToStr(buffer, length);
	if (*buffer != 0) {
		OS.LocalFree(cast(HLOCAL)buffer);
	}
	return errorNum ~ buffer1;
}

// @@--------------------------------------------------------------------------
//
version(none) {
bool CreateProcess(string commandLine) {
	auto hHeap = OS.GetProcessHeap();
	/* Use the character encoding for the default locale */
	StringT buffer = StrToTCHARs(0, commandLine, true);
	auto byteCount = buffer.length  * TCHAR.sizeof;
	auto lpCommandLine = cast(TCHAR*)OS.HeapAlloc (hHeap, OS.HEAP_ZERO_MEMORY, byteCount);
	OS.MoveMemory(lpCommandLine, buffer.ptr, byteCount);
	STARTUPINFO lpStartupInfo;
	lpStartupInfo.cb = STARTUPINFO.sizeof;
	PROCESS_INFORMATION lpProcessInformation;
	bool success = cast(bool) OS.CreateProcess(null, lpCommandLine, null, null, false, 0, null, null, &lpStartupInfo, &lpProcessInformation);
	if (lpCommandLine !is null)
		OS.HeapFree (hHeap, 0, lpCommandLine);
	if (lpProcessInformation.hProcess !is null)
		OS.CloseHandle (lpProcessInformation.hProcess);
	if (lpProcessInformation.hThread !is null)
		OS.CloseHandle (lpProcessInformation.hThread);
	return success;
}}
/*
  dwt のTreeView の設定変更する
TVS_HASLINES -------------- ライン表示
TVS_EX_AUTOHSCROLL--------- 自動的に横するロールする
TVS_EX_FADEINOUTEXPANDOS--- マウスのフォーカスが外れると展開マークをフェードアウトする
*/
void SetTreeViewStyle(HANDLE handle) {
	// add TVS_HASLINES;
    int lStyle = OS.GetWindowLong(handle, OS.GWL_STYLE);
    if ((lStyle & OS.TVS_HASLINES) == 0) {
        lStyle |= OS.TVS_HASLINES;
        OS.SetWindowLong(handle, OS.GWL_STYLE, lStyle);
    }
	// TreeView_GetExtendedStyle(handle)
	// delete TVS_EX_AUTOHSCROLL
	int exStyle = OS.SendMessage(handle, OS.TVM_GETEXTENDEDSTYLE, 0, 0);
	/*
	if (exStyle & OS.TVS_EX_AUTOHSCROLL) {
    	exStyle &= ~OS.TVS_EX_AUTOHSCROLL;
		OS.SendMessage(handle, OS.TVM_SETEXTENDEDSTYLE, 0, exStyle);
	}
	*/
	// delete TVS_EX_FADEINOUTEXPANDOS
	if (exStyle & OS.TVS_EX_FADEINOUTEXPANDOS) {
		exStyle &= ~OS.TVS_EX_FADEINOUTEXPANDOS;
	    OS.SendMessage(handle, OS.TVM_SETEXTENDEDSTYLE, 0, exStyle);
    }
}

// @@--------------------------------------------------------------------------
//
//
extern (Windows) nothrow @nogc {
	
    HRESULT SHEmptyRecycleBinA(HWND, LPCSTR, DWORD);
    HRESULT SHEmptyRecycleBinW(HWND, LPCWSTR, DWORD);
    
	version = Unicode;
	version(Unicode) {
    	alias SHEmptyRecycleBinW SHEmptyRecycleBin;
	} else {
    	alias SHEmptyRecycleBinA SHEmptyRecycleBin;
}
}

bool EmptyRecycleBin() {
	enum SHERB_NOCONFIRMATION = 1; //No dialog box confirming the deletion of the objects will be displayed./削除の確認ダイアログを表示しない
	enum SHERB_NOPROGRESSUI   = 2; //No dialog box indicating the progress will be displayed./削除のプログレス（進行度）ダイアログを表示しない
	enum SHERB_NOSOUND        = 4; //No sound will be played when the operation is complete./削除終了時サウンドを再生しない

	return (
		SHEmptyRecycleBin(null, null, 
			SHERB_NOCONFIRMATION 
			| SHERB_NOPROGRESSUI 
			| SHERB_NOSOUND)
		== 0);
}

// @@--------------------------------------------------------------------------

WindowManager wm;

class WindowManager
{
public Clipboard clipboard;

private:
	Display display;
	Shell   shell;
	Label   statusLine;
	
	void init() {
		if (display is null) {
			display = new Display();
			clipboard = new Clipboard(display);
			display.systemFont = new Font(display, new FontData("Meiryo UI", 10, SWT.NORMAL));
			
		}
		shell = new Shell(display);
	}

public:
	this() {
		init();
	}
	this(string title) {
		init();
		window(title);
	}
	void window(string title, uint width = 800, uint hight = 600) {
		// create window
		shell.setText(title);
		shell.setSize(width, hight);
		shell.setLayout(new GridLayout(1, false));
	}
	Display getDisplay() {
		return display;
	}
	Shell getShell() {
		return shell;
	}
	void run() {
		// shell.pack();
		shell.open();
		while(!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		imageDispose();
		clipboard.dispose();
		display.dispose();
	}
//-----------------------------------------------------------------------------
// Images
//-----------------------------------------------------------------------------
	Image[] images;
	Image image(string filePath) {
		Image img;
		if (filePath !is null && filePath.exists()) {
			img = new Image(display, filePath);
			images ~= img;
		}
		return img;
	}
	void imageDispose() {
		if (images.length) {
			foreach (v ; images) {
				v.dispose();
			}
		}
	}
	void beep() {
		display.beep();
	}
//-----------------------------------------------------------------------------
// Load Window Resouce
// http://www.nda.co.jp/memo/iconscale/
// http://home.att.ne.jp/banana/akatsuki/doc/mfc/mfc10/
//-----------------------------------------------------------------------------
	static const int IDL_ICON = 100;

	Image loadIcon() {
		//loadIcon
		// int cx = OS.GetSystemMetrics(OS.SM_CXSMICON);  // スモールアイコンの幅
		// int cy = OS.GetSystemMetrics(OS.SM_CYSMICON);  // スモールアイコンの高さ
		// auto hIcon = OS.LoadImage(null, cast(wchar*)IDL_ICON, OS.IMAGE_ICON, 0, 0, OS.LR_SHARED);
		auto hIcon = OS.LoadIcon(OS.GetModuleHandle(null), cast(const wchar*)IDL_ICON);
		return Image.win32_new(null, SWT.ICON, hIcon);
	}


//-----------------------------------------------------------------------------
//  Color
//-----------------------------------------------------------------------------
	// SWT.COLOR_DARK_GRAY;
	// SWT.COLOR_WHITE
	// SWT.COLOR_GRAY
	Color getSystemColor(int id) {
		return display.getSystemColor(id);
	}
	Color getColor(int red, int green, int blue) {
		int rgb = (red & 0xFF) | ((green & 0xFF) << 8) | ((blue & 0xFF) << 16);
		return Color.win32_new(display, rgb);
	}
//-----------------------------------------------------------------------------
// widgets
//-----------------------------------------------------------------------------
	Button createButton(Composite c, string text = "", int style = 0, int width = 0) {
		if (text is null) {
			text = "OK";
		}
		if (style == 0) {
			style = SWT.PUSH;
		}
		if (width == 0) {
			width = 100;
		}
		Button b = new Button(c, style);
		b.setText(text);
		
		GridData d = new GridData();
		int w = b.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		if (w < width) {
			d.widthHint = width;
		} else {
			d.widthHint = w;
		}
		b.setLayoutData(d);
    	return b;
	}
	
	Label createLabel(Composite c, string text, int style = SWT.NONE) {
		Label l = new Label(c, style);
		l.setText(text);
		return l;
	}
	
	void setStatusLine() {
		statusLine = new Label(shell,  SWT.BORDER /+ SWT.NONE +/);
		statusLine.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
	}
	
	void createHorizotalLine(Composite c) {
        Label line = new Label(c, SWT.SEPARATOR | SWT.HORIZONTAL);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_FILL);
        line.setLayoutData(data);
    }
	
    Composite createRightAlignmentComposite() {
		enum int BUTTON_WIDTH = 70;
		enum int HORIZONTAL_SPACING = 3;
		enum int MARGIN_WIDTH = 0;
		enum int MARGIN_HEIGHT = 2;
        
        Composite c = new Composite(shell, SWT.NONE);
        GridLayout layout = new GridLayout(2, false);
        layout.horizontalSpacing = HORIZONTAL_SPACING;
        layout.marginWidth = MARGIN_WIDTH;
        layout.marginHeight = MARGIN_HEIGHT;
        c.setLayout(layout);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_END);
        c.setLayoutData(data);
        return c;
    }
//-----------------------------------------------------------------------------
// Menu
//-----------------------------------------------------------------------------
	void setMenu() {
		// create menubar
		Menu bar = new Menu(shell, SWT.BAR);
		shell.setMenuBar(bar);
		// add files menu
		Menu fileMenu = addTopMenu(bar, "ファイル(&F)"); 
		addSubMenu(fileMenu, "新規(&N)\tCtrl+N", &fileOpen, SWT.CTRL + 'N');
		addSubMenu(fileMenu, "開く(&O)...\tCtrl+O", &dg_dummy, SWT.CTRL + 'O');
		addSubMenu(fileMenu, "上書き保存(&S)\tCtrl+S", &dg_dummy, SWT.CTRL + 'S');
		addSubMenu(fileMenu, "名前を付けて保存(&A)...", &dg_dummy);
		addMenuSeparator(fileMenu);
		addSubMenu(fileMenu, "終了(&X)", &dg_exit);
		// add ...
		Menu setupMenu = addTopMenu(bar, "設定(&S)"); 
		addSubMenu(setupMenu, "FontDialog", &selectFont);
		addSubMenu(setupMenu, "ColorDialog", &selectColor);
		addMenuSeparator(setupMenu);
		addSubMenu(setupMenu, "About", &dg_dummy);
	}
	Menu addTopMenu(Menu bar, string text) {
		// menu top
		MenuItem menuItem = new MenuItem(bar, SWT.CASCADE);
		menuItem.setText(text);
		// menu 
		Menu menu = new Menu(bar);
		menuItem.setMenu(menu);
		return menu;
	}
	void addSubMenu(Menu menu, string text, void delegate() dg, int accelerator = 0) {
		MenuItem item = new MenuItem(menu, SWT.PUSH);
		item.setText(text);
		if (accelerator != 0) {
			item.setAccelerator(accelerator); // SWT.CTRL + 'A'
		}
		item.addSelectionListener(new class SelectionAdapter {
                override void widgetSelected(SelectionEvent event) {
                    dg();
				}
			}
		);
		
/**		item.addArmListener(new class ArmListener {
				void widgetArmed(ArmEvent event) {
				//	statusLine.setText((cast(MenuItem)event.getSource()).getText());
				}
			}
		);
*/	}
    void addMenuSeparator(Menu menu) {
		new MenuItem(menu, SWT.SEPARATOR);
	}
//----------------------
    void dg_dummy() {
	}
	void dg_exit() {
		shell.close();
	}
	void fileOpen() {
		FileDialog dialog = new FileDialog(shell, SWT.OPEN);
		dialog.setFilterExtensions(["*.d", "*.java", "*.*"]);
		string fname = dialog.open();
		if (fname.length != 0) {
		}
    	
    }
	void selectFont() {
		FontDialog fontDialog = new FontDialog(shell);
		// set current Font to FontDialog
		fontDialog.setFontList(shell.getFont().getFontData());
		FontData fontData = fontDialog.open();
//		if (fontData !is null) {
//			if (shell.font !is null)
//				shell.font.dispose();
//			Font font = new Font(display, fontData);
//			shell.setFont(font);
//		}
	}
/*
private static Font loadMonospacedFont(Display display) {
	String jreHome = System.getProperty("java.home");
	File file = new File(jreHome, "/lib/fonts/LucidaTypewriterRegular.ttf");
	if (!file.exists()) {
		throw new IllegalStateException(file.toString());
	}
	if (!display.loadFont(file.toString())) {
		throw new IllegalStateException(file.toString());
	}
	final Font font = new Font(display, "Lucida Sans Typewriter", 10, SWT.NORMAL);
	display.addListener(SWT.Dispose, new Listener() {
		public void handleEvent(Event event) {
			font.dispose();
		}
	});
	return font;
}
*/
	void  selectColor() {
		ColorDialog colorDialog = new ColorDialog(shell);
		colorDialog.open();
//		colorDialog.setRGB(text.getForeground().getRGB());
//		RGB rgb = colorDialog.open();
//
//		if (rgb !is null) {
//			if (foregroundColor !is null) {
//				foregroundColor.dispose();
//			}
//			foregroundColor = new Color(display, rgb);
//			text.setForeground(foregroundColor);
//		}
	}
	
	string selectDirecoty(string setpath) {
		DirectoryDialog ddlg = new DirectoryDialog(shell);
		ddlg.setFilterPath(setpath);
		ddlg.setText("DirectoryDialog");
		ddlg.setMessage("Select a directory");
		return ddlg.open();
	}
}


