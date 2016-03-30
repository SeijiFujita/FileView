// Written in the D programming language.
//
// dwt_base.d
// dmd 2.070.0
//
module utils;

import std.conv;
import std.file;
import std.path;

//------------------------------------------------------------------------------
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
			Remove(toFile);
			std.file.copy(fromFile, toFile);
		}
	}
	else {
		throw new Exception("CopyFiletoDir Error. See " ~ __FILE__ ~ to!string(__LINE__));
	}
}

version (none) {
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
}
}

