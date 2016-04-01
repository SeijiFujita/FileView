// Written in the D programming language.
//
// dwt_base.d
// dmd 2.070.0
//
module utils;

import org.eclipse.swt.internal.win32.OS;
import org.eclipse.swt.internal.win32.WINAPI;
import java.lang.all;

import std.conv;
import std.file;
import std.path;

import dlsbuffer;

//@------------------------------------------------------------------------------
// Utils

version (Windows) {
	enum isWindows = true;
	enum pathDelimiter = "\\";
} else {
	enum isWindows = false;
	enum pathDelimiter = "/";
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

void CopyFiletoDir(string fromFile, string todir) {
	if (fromFile.exists()) {
		if (!todir.exists()) {
			MakeDir(todir);
		}
		if (todir.isDir()) {
			string toFile = todir ~ pathDelimiter ~ baseName(fromFile);
			dlog("CopyFiletoDir:fromFile: ", fromFile);
			dlog("CopyFiletoDir:toFile  : ", toFile);
			if (fromFile != toFile) {
				if (toFile.exists()) {
					RecycleBin(toFile);
				}
				std.file.copy(fromFile, toFile);
				dlog("copy done..");
			}
			else {
				dlog("do not copy...");
			}
		}
	}
	else {
		throw new Exception("CopyFiletoDir Error. See " ~ __FILE__ ~ to!string(__LINE__));
	}
}
void RecycleBin(string file) {
	string[] rb = [ file ];
	RecycleBin(rb);
}

void RecycleBin(string[] files) {
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
}

string getLastErrorText() {
    int error = OS.GetLastError();
    if (error is 0)
    	return "";
    TCHAR* buffer = null;
    int dwFlags = OS.FORMAT_MESSAGE_ALLOCATE_BUFFER | OS.FORMAT_MESSAGE_FROM_SYSTEM | OS.FORMAT_MESSAGE_IGNORE_INSERTS;
    int length = OS.FormatMessage(dwFlags, null, error, OS.LANG_USER_DEFAULT, cast(TCHAR*)&buffer, 0, null);
    string errorNum = ("[GetLastError=") ~ .toHex(error) ~ "] ";
    if (length == 0) {
    	return errorNum;
	}
    string buffer1 = .TCHARzToStr(buffer, length);
    if ( *buffer != 0) {
        OS.LocalFree(cast(HLOCAL)buffer);
    }
    return errorNum ~ buffer1;
}

//@------------------------------------------------------------------------------
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

//@------------------------------------------------------------------------------
//
//
extern (Windows) nothrow @nogc {
    HRESULT SHEmptyRecycleBinA(HWND, LPCSTR, DWORD);
    HRESULT SHEmptyRecycleBinW(HWND, LPCWSTR, DWORD);
}
version = Unicode;
version(Unicode) {
    alias SHEmptyRecycleBinW SHEmptyRecycleBin;
} else {
    alias SHEmptyRecycleBinA SHEmptyRecycleBin;
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


