// Written in the D programming language.
/*
 * dmd 2.070.0 - 2.075.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module filetable;

import org.eclipse.swt.all;
import org.eclipse.swt.internal.win32.OS;
import org.eclipse.swt.internal.win32.WINAPI;
import java.lang.all;

import std.file;
import std.path;
import std.string;

import windowmgr;
import utils;
import dlsbuffer;
import main;

class FileTable
{
private:
	Table fileTable;
	string tablePath;
	uint tableItemcount;
	bool show_directory;
	bool show_advancedMenu;
	// int  enterRenameIndex;
	// int  enterRenameCount;
	Color tableItemBackgroundColor;
	Color tableItemClipboardCutColor;
	
public:
	void delegate(string path = null) updateFolder;

	this() {
		show_directory = true;
		tableItemBackgroundColor = wm.getColor(230, 230, 230);
		tableItemClipboardCutColor = wm.getColor(40, 40, 240);
	}
	
	void initUI(Composite parent, string path) {
		fileTable = new Table(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.MULTI | SWT.FULL_SELECTION);
		fileTable.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		setTableColumn();
		setDragDrop(fileTable);
		setPopup(fileTable);
		reloadFileTable(path);
		dlog("initUI:path ", path);
		
		fileTable.addListener(SWT.MouseDoubleClick, new class Listener {
			void handleEvent(Event event) {
				dlog("MouseDoubleClick");
				// enterRenameIndex = 0;
				int index = fileTable.getSelectionIndex();
				int count = fileTable.getSelectionCount();
				if (index >= 0 && count == 1) {
					selectFunction();
				}
			}
		});
		/*
		MouseDoubleClick と競合してタイミングが悪いと問題が発生する事がある
		
		fileTable.addListener(SWT.MouseDown, new class Listener {
			void handleEvent(Event event) {
				dlog("MouseDown");
				// 同じファイル(テーブル)を二度クリックすることにより
				// Renameモード(テーブルの編集)に入る
				// index == 0 is first table
				int index = fileTable.getSelectionIndex();
				if (index < 0) {
					enterRenameIndex = 0;
					enterRenameCount = 0;
				} else if (index != enterRenameIndex) {
					enterRenameIndex = index;
				} else {
					++enterRenameCount;
				}
				if (enterRenameCount >= 2) {
					fileTableEditor();
					enterRenameCount = 0;
				}
			}
		});
		*/
	}
/*
	bool checkFileRename(string fn) {
		string ex = "\\/:*?\"<>|";
		foreach (v ; ex) {
			if (std.string.indexOf(fn, v)) {
				return false;
			}
		}
		return true;
	}
*/	
	void selectFunction() {
		int index = fileTable.getSelectionIndex();
		auto item = cast(fileTableItem) fileTable.getItem(index);
		if (index >= 0 && item !is null) {
			string path = item.getfullPath();
			if (path.isDir()) {
				updateFolder(path);
			} else {
				extentionOpen();
			}
		}
	}
	void fileTableEditor() {
		enum EditCOLUMN = 0;
		enum MAX_PATH_LEN = 260; // for Windows SPEC.
		enum MAX_FILE_LEN = 100; // About my feeling
		
		int count = fileTable.getSelectionCount();
		int index = fileTable.getSelectionIndex();
		auto item = cast(fileTableItem) fileTable.getItem(index);
		dlog("count: ", count);
		dlog("index: ", index);
		if (count == 1 && index >= 0 && item !is null) {
			TableEditor tableEditor = new TableEditor(fileTable);
			tableEditor.grabHorizontal = true;
			//TableCursor cursor = new TableCursor(table, SWT.NONE);
			//cursor.setVisible(false);
			//cursor.setVisible(true);
			
			string beforeFuillPath = item.getfullPath();
			string beforeEditData = item.getText(EditCOLUMN);
			if (beforeFuillPath.length > MAX_PATH_LEN || beforeEditData.length > MAX_FILE_LEN) {
				return;
			}
			//
			void doRename(string beforeFuillPath, string afeterEditData) {
				if (baseName(beforeEditData) != afeterEditData) {
					string fromfile = beforeFuillPath;
					string tofile = dirName(beforeFuillPath) ~ "\\" ~ afeterEditData;
					SHFileOperationRename(fromfile, tofile);
					reloadFileTable();
				}
			}
			
			// Text で編集を行う
			Text newEditor = new Text(fileTable, SWT.SINGLE | SWT.BORDER);
			newEditor.setText(beforeEditData);
			newEditor.setFocus();
			newEditor.selectAll();
			tableEditor.setEditor(newEditor, item, EditCOLUMN);
			// 特定のキャラクタを入力禁止にする
			newEditor.addVerifyListener(new class VerifyListener {
				void verifyText(VerifyEvent e) {
					if (std.string.indexOf("\\/:*?\"<>|", e.character) >= 0) {
						wm.beep();
						e.doit = false;
					}
				}
			});
			// ENTERとESCが押されたときの処理
			newEditor.addKeyListener(new class KeyAdapter {
				override void keyReleased(KeyEvent e) {
					dlog("e.character: ", e.character);
					dlog("e.keyCode: ", e.keyCode);
					if (e.character == SWT.CR) {
						dlog("CR kye: ", newEditor.getText());
						string afeterEditData = newEditor.getText();
						auto item = tableEditor.getItem();
						item.setText(EditCOLUMN, afeterEditData);
						doRename(beforeFuillPath, afeterEditData);
						newEditor.dispose();
						tableEditor.dispose();
					} else if (e.character == SWT.ESC) {
						dlog("ESC kye");
						newEditor.dispose();
						tableEditor.dispose();
					}
				}
			});
			// フォーカスが外れたときの処理
			newEditor.addFocusListener(new class FocusAdapter {
				override void focusLost(FocusEvent e) {
					dlog("focusLost: ", newEditor.getText());
					string afeterEditData = newEditor.getText();
					auto item = tableEditor.getItem();
					item.setText(EditCOLUMN, afeterEditData);
					doRename(beforeFuillPath, afeterEditData);
					newEditor.dispose();
					tableEditor.dispose();
				}
			});
		}
	}
	void setTableColumn() {
		struct TableTitle {
			string name;
			int size;
			int alignment;
	 	}
		TableTitle[] tableTitles = [ 
			TableTitle("Name", 250, SWT.LEFT),
			TableTitle("Size", 100, SWT.RIGHT),
			TableTitle("Date", 120, SWT.LEFT)
		];
		TableColumn column;
		foreach (v ; tableTitles) {
			column = new TableColumn(fileTable, SWT.NONE);
			column.setText(v.name);
			column.setWidth(v.size);
			column.setAlignment(v.alignment);
		}
		fileTable.setHeaderVisible(true);
	}
	
	void reloadFileTable() {
		if (tablePath !is null) {
			reloadFileTable(tablePath);
		}
	}
	void reloadFileTable(string path) {
		if (fileTable !is null) {
			dlog("reloadFileTable");
			fileTable.removeAll();
			tableItemcount = 0;
			tablePath = path;
			try {
				if (show_directory) {
					addTable(fileTable, dirName(path), "<dir>", fileDateString(path), true);
					foreach (DirEntry e; dirEntries(path, SpanMode.shallow)) {
						if (e.isDir()) {
							addTable(fileTable, e.name, "<dir>", fileDateString(e.name));
						}
					}
					foreach (DirEntry e; dirEntries(path, SpanMode.shallow)) {
						if (e.isFile()) {
							addTable(fileTable, e.name, fileSizeString(e.size), fileDateString(e.name));
						}
					}
				}
				else {	// not show dirEntries
					addTable(fileTable, dirName(path), "<dir>", fileDateString(path), true);
					foreach (DirEntry e; dirEntries(path, SpanMode.shallow)) {
						if (e.isFile()) {
							addTable(fileTable, e.name, fileSizeString(e.size), fileDateString(e.name));
							// addTable(fileTable, e.name, e.size);
						}
					}
				}
			}
			catch(Exception e) {
				dlog("Exception: ", e.toString());
			}
		}
	}
	void addTable(Table node, string filepath, string size, string date, bool parentPath = false) {
		fileTableItem item = new fileTableItem(node, SWT.NONE);
		if (++tableItemcount % 2) {
			item.setBackground(tableItemBackgroundColor);
		}
		item.setfullPath(filepath);
		item.setImage(0, getFilesIcon(filepath));
		
		if (parentPath) {
			item.setText(["..", size, date]);
		} else {
			item.setText([baseName(filepath), size, date]);
		}
	}
	
	class fileTableItem : TableItem
	{
		private string fullPath;
		
		this(Table parent, int style) {
			super(parent, style);
		}
		void setfullPath(string f) {
			fullPath = f;
		}
		string getfullPath() {
			return fullPath;
		}
	}
	string fileSizeString(ulong fs) {
		string fileSize;
		double dfs;
		if (fs < 1024) {  //  < KB
			fileSize = format("%10d  B", fs);
		} else if (fs < 1024 * 1000) { // < MB
			dfs = cast(double)fs / 1024.0;
			fileSize = format("%10.2f KB", dfs);
		} else if (fs < 1024 * 1000 * 1000) { // < GB
			dfs = cast(double)fs / (1024.0 * 1000);
			fileSize = format("%10.2f MB", dfs);
		} else { // if (e.size < 1024 * 1000 * 1000 * 1000) { // < TB
			dfs = cast(double)fs / (1024.0 * 1000 * 1000);
			fileSize = format("%10.2f GB", dfs);
		}
		return fileSize;
	}
	string fileDateString(string fn) {
		import std.datetime;
		
		SysTime ctm = Clock.currTime();
		SysTime ftm = timeLastModified(fn);
		string fileDate;
		
		with (ftm) {
			// 'ls -l' のようにファイルのタイムスタンプが今年の場合は時間を表示する
			// Like 'ls -l' command. If the time stamp of the file is this year, it displays time. 
			if (ctm.year == year) {
				fileDate = format("%02d/%02d %02d:%02d:%02d", month, day, hour, minute, second);
			} else {
				fileDate = format("%02d/%02d  %04d", month, day, year); 
			}
		}
		return fileDate;
	}
	// Popup Menu
	void setPopup(Table parent) {
		Menu menu = new Menu(parent);
		parent.setMenu(menu);
		
		addPopupMenu(menu, "extentionOpen", &extentionOpen);
		//--------------------
		addMenuSeparator(menu);
		addPopupMenu(menu, "Hidemaru", &execHidemaru);
		addPopupMenu(menu, "Emacs", &execEmacs);
		addPopupMenu(menu, "VSCode", &execVSCode);
		addPopupMenu(menu, "FileView", &execFileView);
		addPopupMenu(menu, "FindFile", &execFileFind);
		addPopupMenu(menu, "Msys", &execMsys);
		addPopupMenu(menu, "CMD", &execCmd);
		//--------------------
		addMenuSeparator(menu);
		auto itemCut    = addPopupMenu(menu, "Cut", &execCut);
		auto itemCopy   = addPopupMenu(menu, "Copy", &execCopy);
		auto itemPasete = addPopupMenu(menu, "Pasete", &execPasete);
		addMenuSeparator(menu);
		//--------------------
		addPopupMenu(menu, "NewFile", &execNewFile);
		addPopupMenu(menu, "NewFolder", &execNewDirectory);
		addPopupMenu(menu, "Delete", &execRecycleBin);
		addPopupMenu(menu, "Rename", &execRename);
		addMenuSeparator(menu);
		addPopupMenu(menu, "ReloadAll", &reloadAll);
		auto itemShowDirectory = addPopupMenu(menu, "ShowDirectory", &toggle_showDirectory, 0, SWT.CHECK);
		addPopupMenu(menu, "Advanced Menu", &toggle_advanceMenu, 0, SWT.CHECK);
		addMenuSeparator(menu);
		//--------------------
		auto itemDirectDelete   = addPopupMenu(menu, "Delete(do Not recycle)", &execDelete);
		auto itemClipbordClear  = addPopupMenu(menu, "ClipbordDataClear", &execClipboardClear);
		
		menu.addMenuListener(new class MenuAdapter {
			override void menuShown(MenuEvent e) {
				// ShowDirectorys
				itemShowDirectory.setSelection(show_directory);
				
				// cut & copy menu enable & disable
				int count = fileTable.getSelectionCount();
				itemCut.setEnabled(count > 0);
				itemCopy.setEnabled(count > 0);
				
				// is paste valid
				TransferData[] available = wm.clipboard.getAvailableTypes();
				dlog("menuShown:available.length: ", available.length);
				dlog("menuShown:available :", available);
				bool enabled = false;
				for (int i = 0; i < available.length; i++) {
					if (FileTransfer.getInstance().isSupportedType(available[i])) {
						enabled = true;
						break;
					}
				}
				itemPasete.setEnabled(enabled);
				itemClipbordClear.setEnabled(enabled && show_advancedMenu);
				//advanced menu
				itemDirectDelete.setEnabled(show_advancedMenu);
			}
		});
	}
	
	MenuItem addPopupMenu(Menu menu, string text, void delegate() dg, int accelerator = 0, int style = SWT.NONE) {
		MenuItem item = new MenuItem(menu, style);
		item.setText(text);
		if (accelerator != 0) {
			item.setAccelerator(accelerator); // SWT.CTRL + 'A'
		}
		item.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent event) {
				dg();
			}
		});
		return item;
	}
    
    void addMenuSeparator(Menu menu) {
		new MenuItem(menu, SWT.SEPARATOR);
	}
	
	void dg_dummy() {
	}
	void reloadAll() {
		reloadFileTable();
	}
	void toggle_showDirectory() {
		show_directory = show_directory ? false : true;
		reloadFileTable();
	}
	void toggle_advanceMenu() {
		show_advancedMenu = show_advancedMenu ? false : true;
	}
	void extentionOpen() {
		dlog("extentonOpen");
		fileTableItem[] items = cast(fileTableItem[]) fileTable.getSelection();
		if (items.length == 1) {
			string file = items[0].getfullPath();
			string ext = extension(file);
			if (file !is null && ext !is null) {
				dlog("file: ", file);
				dlog("ext: ", ext);
				auto p = Program.findProgram(ext);
				dlog("command: ", p.command);
				chdir(tablePath);
				p.execute(file);
			}
		}
		reloadFileTable();
	}
	void execHidemaru() {
		fileTableItem[] items = cast(fileTableItem[]) fileTable.getSelection();
		if (items.length) {
			string prog = "\"C:\\Program Files (x86)\\Hidemaru\\hidemaru.exe\"";
			string param;
			foreach(v ; items) {
				param ~= " " ~ v.getfullPath();
			}
			CreateProcess(prog ~ param);
			reloadFileTable();
		}
	}
	void execVSCode() {
		fileTableItem[] items = cast(fileTableItem[]) fileTable.getSelection();
		if (items.length) {
			// string prog = "\"C:\\Program Files (x86)\\Microsoft VS Code\\bin\\code.cmd\"";
			string prog = "\"C:\\Program Files (x86)\\Microsoft VS Code\\Code.exe\"";
			string param;
			foreach(v ; items) {
				param ~= " " ~ v.getfullPath();
			}
			CreateProcess(prog ~ param);
			reloadFileTable();
		}
	}
	void execEmacs() {
		// C:\emacs\emacs.bat
		dlog("execEmacs");
		fileTableItem[] items = cast(fileTableItem[]) fileTable.getSelection();
		if (items.length) {
			string prog = "C:\\emacs\\emacs.bat";
			string param;
			foreach(v ; items) {
				param ~= " " ~ v.getfullPath();
			}
			CreateProcess(prog ~ param);
			reloadFileTable();
		}
	}
	void execFileView() {
		immutable string prog = "fileView64.exe";
		immutable string param = " " ~ tablePath;
		CreateProcess(prog ~ param);
	}
	void execFileFind() {
		immutable string prog = "fileFind64.exe";
		immutable string param = " " ~ tablePath;
		CreateProcess(prog ~ param);
	}
	void execMsys() {
		string prog = "C:\\MinGW32\\Mintty.bat";
		CreateProcess(prog);
	}
	void execCmd() {
		dlog("execCmd");
		string prog = "CMD.EXE";
		chdir(tablePath);
		CreateProcess(prog);
	}
	void execDelete() {
		if (fileTable.getSelectionCount() != 0) {
			auto items = cast(fileTableItem[]) fileTable.getSelection();
			foreach (v ; items) {
				Remove(v.getfullPath());
			}
			reloadFileTable();
		}
	}
	// Delete
	void execRecycleBin() {
		if (fileTable.getSelectionCount() != 0) {
			auto items = cast(fileTableItem[]) fileTable.getSelection();
			string[] rb;
			foreach (v ; items) {
				rb ~= v.getfullPath();
			}
			RecycleBin(rb);
			reloadFileTable();
		}
	}
	// @@----------------------------------------------------------------------
	// Clipborad 
	bool clipboardCutFlag; // false:copy / true:cut
	//
	void clipboradCutAndCopy(bool cutFlag = false) {
		// clipboard copy
		if (fileTable.getSelectionCount() != 0) {
			dlog("clipboradCutAndCopy: ", cutFlag);
			auto items = cast(fileTableItem[]) fileTable.getSelection();
			string[] buff;
			foreach (v ; items) {
				buff ~= v.getfullPath();
				if (cutFlag) {
					v.setForeground(tableItemClipboardCutColor);
				}
			}
			Object[] data = [new ArrayWrapperString2(buff) ];
			Transfer[] types = [ FileTransfer.getInstance() ];
			wm.clipboard.setContents(data, types);
			clipboardCutFlag = cutFlag;
		
		}
	}
	bool clipbordAvailable() {
		TransferData[] available = wm.clipboard.getAvailableTypes();
		bool enabled = false;
		if (available !is null) {
			for (int i = 0; i < available.length; i++) {
				if (FileTransfer.getInstance().isSupportedType(available[i])) {
					enabled = true;
					break;
				}
			}
		}
		return enabled;
	}
	int findItems(string text) {
		if (fileTable !is null && fileTable.items.length) {
			foreach (int i, v; fileTable.items) {
		    	if (text == v.getText()) {
					return i;
				}
			}
		}
		return -1;
	}
	void setStringSelection(string[] copyedFiles) {
		int[] indices;
		
		foreach (v ; copyedFiles) {
	    	int i = findItems(std.path.baseName(v));
	    	if (i > -1) {
				indices ~= i;
			}
		}
		if (indices.length) {
			fileTable.setSelection(indices);
		}
	}
	void clipbordPasete() {
		if (clipbordAvailable()) {
			string[] buff = stringArrayFromObject(wm.clipboard.getContents(FileTransfer.getInstance()));
			dlog("execPasete:buff ", buff);
			if (buff !is null && buff.length && checkCopy(buff[0], tablePath)) {
				foreach(v ; buff) {
					int status = CopyFiletoDir(v, tablePath);
					if (status == 0 && clipboardCutFlag) {
						// delete source file
						RecycleBin(v);
					}
				}
				clipboardCutFlag = false;
				reloadFileTable();
				setStringSelection(buff);
			}
		}
	}
	void clipboardClear() {
		wm.clipboard.clearContents();
		clipboardCutFlag = false;
		reloadFileTable();
	}
	// @@----------------------------------------------------------------------
	void execCut() {
		clipboradCutAndCopy(true);
	}
	void execCopy() {
		clipboradCutAndCopy();
	}
	void execPasete() {
		clipbordPasete();
	}
	void execClipboardClear() {
		clipboardClear();
	}
	void execRename() {
		fileTableEditor();
	}
	void execNewFile() {
		string newFile = tablePath ~ PathDelimiter ~ "newfile.txt";
		if (newFile.exists() && newFile.isFile()) {
			RecycleBin(newFile);
		}
		std.file.write(newFile, "// hello\n");
		reloadFileTable();
	}
	void execNewDirectory() {
		show_directory = true;
		string newFolder = tablePath ~ PathDelimiter ~ "newFolder";
		if (!(newFolder.exists() && newFolder.isDir())) {
			MakeDir(newFolder);
			updateFolder();
		}
	}
	bool CreateProcess(string commandLine) {
		auto hHeap = OS.GetProcessHeap();
		/* Use the character encoding for the default locale */
		StringT buffer = StrToTCHARs(0, commandLine, true);
		auto byteCount = buffer.length  * TCHAR.sizeof;
		auto lpCommandLine = cast(TCHAR*)OS.HeapAlloc(hHeap, OS.HEAP_ZERO_MEMORY, byteCount);
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
	
	// 同じファイルにコピーしない
	// use execPasete()
	// use drop(DropTargetEvent event)
	bool checkCopy(string from, string todir) {
		string srcdir = dirName(from);
		bool result;
		if (srcdir == todir) {
			result = false;
		} else {
			result = true;
		}
		dlog("checkCopy:srcdir: ", srcdir);
		dlog("checkCopy:todir : ", todir);
		dlog("checkCopy:result: ", result);
		return result;
	}
	
	bool self_DragFlag;
	// DND.DROP_COPY のみをサポート
	// DND.DROP_MOVE は行わない
	void setDragDrop(Table tt) {
		// windows explorer の仕様
		// drag only    : DROP_DEFAULT application default の動作は移動(DND.DROP_MOVE)
		// drag + SHIFT : DND.DROP_MOVE
		// drag + CTRL  : DND.DROP_COPY
		// drag + CTRL + SHIFT : DND.DROP_LINK;
		
		int operations = DND.DROP_COPY;
		// int operations = DND.DROP_MOVE | DND.DROP_COPY;
		//
		DragSource source = new DragSource(tt, operations);
		source.setTransfer([FileTransfer.getInstance()]);
		source.addDragListener(new class DragSourceListener {
			// event.doit = true でドラックできる事をOLEに知らせる
			override void dragStart(DragSourceEvent event) {
				dlog("dragStart:event.detail: ", event.detail);
				self_DragFlag = true;
				event.doit = (tt.getSelectionCount() != 0);
			}
			// ドラックするデータを作成し evet.data にセット
			override void dragSetData(DragSourceEvent event) {
				dlog("dragSetData: event.detail: ", event.detail);
				auto items = cast(fileTableItem[]) tt.getSelection();
				string[] buff;
				foreach (v ; items) {
					buff ~= v.getfullPath();
				}
				dlog("buff ", buff);
				event.data = new ArrayWrapperString2(buff);
				event.detail = DND.DROP_COPY;
			}
			// ドロップ後(貼り付け後)の終了処理
			// 移動を行った後はソースを削除しないと移動にならない
			override void dragFinished(DragSourceEvent event) {
				dlog("dragFinished event: ", event);
				dlog("event.detail: ", event.detail);
				dlog("DND.DROP_COPY: ", DND.DROP_COPY);
				dlog("DND.DROP_MOVE: ", DND.DROP_MOVE);
				dlog("DND.DROP_DEFAULT: ", DND.DROP_DEFAULT);
version (none) {
// ファイルを消すのはやっぱ問題あるよｗ
				if (event.detail == DND.DROP_MOVE) {
					dlog("delete");
					// delete move files;
					auto items = cast(fileTableItem[]) tt.getSelection();
					foreach (v ; items) {
						Remove(v.getfullPath());
					}
					updateFolder();
				}
} // version
				self_DragFlag = false;
				dlog("dragFinished:end");
			}
		});
		//
		DropTarget target = new DropTarget(tt, operations);
		target.setTransfer([FileTransfer.getInstance()]);
		target.addDropListener(new class DropTargetAdapter {
			// ドラッグ中のマウスカーソルが入ってきた時にdragEnterが呼ばれます
			// ドロップ可能な場合はevent.detail = DND.DROP_COPY で応答を行います
			override void dragEnter(DropTargetEvent event) {
				dlog("dragEnter");
				dlog("DropTargetEvent event: ", event);
				if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					event.detail = DND.DROP_COPY;
				} else {
					event.detail = DND.DROP_NONE;
				}
				dlog("DropTargetEvent event: ", event);
			}
			// ドラッグ中に修飾キーが押されて処理が変更された時の処理
			// 修飾キーを押さない場合のドラッグ＆ドロップはコピー
			override void dragOperationChanged(DropTargetEvent event) {
				dlog("dragOperationChanged: event: ", event);
				
			}
			override void drop(DropTargetEvent event) {
				// event.data の内容を確認してドロップに対応した処理を行う
				dlog("drop: DropTargetEvent event: ", event);
				if (self_DragFlag != true && FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string[] buff = stringArrayFromObject(event.data);
					dlog("buff: ", buff);
					dlog("tablePath: ", tablePath);
					if (buff.length >= 1 && checkCopy(buff[0], tablePath)) {
						foreach(v ; buff) {
							CopyFiletoDir(v, tablePath);
						}
						updateFolder();
					}
				}
				dlog("drop: DropTargetEvent event: ", event);
			}
		});
	}
	
}

