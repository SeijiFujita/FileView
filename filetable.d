// Written in the D programming language.
/*
 * dmd 2.070.0
 *
 */

module filetable;

import org.eclipse.swt.all;
import org.eclipse.swt.internal.win32.OS;
import org.eclipse.swt.internal.win32.WINAPI;
import java.lang.all;

import std.file;
import std.path;
import std.string;

import utils;
import dlsbuffer;


class FileTable
{
private:
	bool show_directory;
	bool show_advancedMenu;
	int  enterRenameIndex;
	int  enterRenameCount;
	string tablePath;
	Color tableItemBackgroundColor;
	Table fileTable;
	uint tableItemcount;
	
public:
	void delegate() updateFolder;

	this() {
		tableItemBackgroundColor = wm.getColor(230, 230, 230);
	}
	void initUI(Composite parent, string path) {
		fileTable = new Table(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.MULTI | SWT.FULL_SELECTION);
		fileTable.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		setTableColumn();
		setDragDrop(fileTable);
		setPopup(fileTable);
		reloadFileTable(path);
		
		fileTable.addListener(SWT.MouseDoubleClick, new class Listener {
			void handleEvent(Event event) {
				dlog("MouseDoubleClick");
				enterRenameIndex = 0;
				int index = fileTable.getSelectionIndex();
				int count = fileTable.getSelectionCount();
				if (index >= 0 && count == 1) {
					extentionOpen();
				}
			}
		});
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
	void fileTableEditor() {
		enum EditCOLUMN = 0;
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
			//
			void doRename(string beforeFuillPath, string afeterEditData) {
				if (baseName(beforeEditData) != afeterEditData) {
					string fromfile = beforeFuillPath;
					string tofile = dirName(beforeFuillPath) ~ "\\" ~ afeterEditData;
					SHFileOperationRename(fromfile, tofile);
				}
			}
			
			// Text で編集を行う
			Text newEditor = new Text(fileTable, SWT.NONE);
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
					} else if (e.character == SWT.ESC) {
						dlog("ESC kye");
						newEditor.dispose();
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
			fileTable.removeAll();
			tableItemcount = 0;
			tablePath = path;
			try {
				if (show_directory) {
					// addTable(fileTable, "..", "<dir>", fileDateString(e.name ~ "\\.."));
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
				else {
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
	void addTable(Table node, string filepath, string size, string date) {
		fileTableItem item = new fileTableItem(node, SWT.NONE);
		item.setfullPath(filepath);
		if (++tableItemcount % 2) {
			item.setBackground(tableItemBackgroundColor);
		}
		string[] fileSpec = [baseName(filepath), size, date];
		item.setText(fileSpec);
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
		string fileDate;
		SysTime ctm, ftm;
		try {
			ctm = Clock.currTime();
			ftm = timeLastModified(fn);
			with (ftm) {
				// ls -l みたいにファイルのタイムスタンプが今年の場合は時間を表示する
				if (ctm.year == year)
					fileDate = format("%02d/%02d %02d:%02d:%02d", month, day, hour, minute, second);
				else
					fileDate = format("%02d/%02d  %04d", month, day, year); 
			}
		}
		catch(Exception e) {
			dlog("Exception: ", e.toString());
			fileDate = "n/a";
		}
		return fileDate;
	}
	void setPopup(Table parent) {
		Menu menu = new Menu(parent);
		parent.setMenu(menu);
		
		addPopupMenu(menu, "Hidemaru", &execHidemaru);
		addPopupMenu(menu, "FileView", &execFileView);
		addPopupMenu(menu, "FindFile", &execFileFile);
		addPopupMenu(menu, "Msys", &execMsys);
		addPopupMenu(menu, "CMD", &execCmd);
		addPopupMenu(menu, "extentionOpen", &extentionOpen);
		addMenuSeparator(menu);
		//--------------------
		auto itemCut    = addPopupMenu(menu, "Cut", &execCut);
		auto itemCopy   = addPopupMenu(menu, "Copy", &execCopy);
		auto itemPasete = addPopupMenu(menu, "Pasete", &execPasete);
		addMenuSeparator(menu);
		//--------------------
		addPopupMenu(menu, "NewFile", &execNewFile);
		addPopupMenu(menu, "Delete", &execRecycleBin);
		addPopupMenu(menu, "Rename", &execRename);
		addMenuSeparator(menu);
		addPopupMenu(menu, "ReloadAll", &reloadAll);
		auto itemShowDirectory = addPopupMenu(menu, "ShowDirectory", &toggle_showDirectory, 0, SWT.CHECK);
		addPopupMenu(menu, "Advanced Menu", &toggle_advanceMenu, 0, SWT.CHECK);
		addMenuSeparator(menu);
		//--------------------
		auto itemDirectDelete = addPopupMenu(menu, "Delete(do not recycle)", &execDelete);
		
		
		menu.addMenuListener(new class MenuAdapter {
			override void menuShown(MenuEvent e) {
				
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
		fileTableItem[] items = cast(fileTableItem[]) fileTable.getSelection();
		if (items.length == 1) {
			string file = items[0].getfullPath();
			string ext = extension(file);
			if (ext !is null) {
				dlog("extentonOpen");
				auto p = Program.findProgram(ext);
				dlog("-command: ", p.command);
				p.execute(file);
			}
		}
		reloadFileTable();
	}
	void execHidemaru() {
		fileTableItem[] items = cast(fileTableItem[]) fileTable.getSelection();
		if (items.length) {
			string hidemaru = "\"C:\\Program Files (x86)\\Hidemaru\\hidemaru.exe\"";
			string param;
			foreach(v ; items) {
				string s = " " ~ v.getfullPath();
				param ~= s;
				dlog("v.getfullPath(): ", s);
			}
			CreateProcess(hidemaru ~ param);
			reloadFileTable();
		}
	}
	void execFileView() {
		string prog = "C:\\D\\bin\\fileView01.exe";
		string param = " " ~ tablePath;
		CreateProcess(prog ~ param);
	}
	void execFileFile() {
		string prog = "C:\\D\\bin\\findFile.exe";
		string param = " " ~ tablePath;
		CreateProcess(prog ~ param);
	}
	void execMsys() {
		// C:\emacs\emacs.bat
		string prog = "C:\\MinGW32\\Mintty.bat";
		string param = " " ~ tablePath;
		CreateProcess(prog ~ param);
	}
	void execCmd() {
		// C:\emacs\emacs.bat
		string prog = "CMD.EXE";
		string param = " " ~ tablePath;
		CreateProcess(prog ~ param);
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
	void execCut() {
		// clipboard
		//@
	}
	void execCopy() {
		// clipboard copy
		if (fileTable.getSelectionCount() != 0) {
			auto items = cast(fileTableItem[]) fileTable.getSelection();
			string[] buff;
			foreach (v ; items) {
				buff ~= v.getfullPath();
			}
			Object[] data = [new ArrayWrapperString2(buff) ];
			Transfer[] types = [ FileTransfer.getInstance() ];
			wm.clipboard.setContents(data, types);
		}
	}
	void execPasete() {
		string[] buff = stringArrayFromObject(wm.clipboard.getContents(FileTransfer.getInstance()));
		dlog("execPasete:buff ", buff);
		if (buff !is null && buff.length && checkCopy(buff[0], tablePath)) {
			foreach(v ; buff) {
				CopyFiletoDir(v, tablePath);
			}
			reloadFileTable();
		}
	}
	void execRename() {
		fileTableEditor();
	}
	void execNewFile() {
		string newFile = tablePath ~ PathDelimiter ~ "newfile.txt";
		std.file.write(tablePath, "// hello");
		reloadFileTable();
	}
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
				if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
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

