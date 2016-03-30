// Written in the D programming language.
//
// dwt_base.d
// dmd 2.070.0
// 
// http://www.java2s.com/Code/Java/SWT-JFace-Eclipse/CatalogSWT-JFace-Eclipse.htm
// http://www.java2s.com/Code/JavaAPI/org.eclipse.swt.widgets/Catalogorg.eclipse.swt.widgets.htm
// http://www.java2s.com/Tutorial/Java/0280__SWT/Catalog0280__SWT.htm
// http://study-swt.info/
//
// 
import org.eclipse.swt.all;
import org.eclipse.swt.internal.win32.OS;
import org.eclipse.swt.internal.win32.WINAPI;
import java.lang.all;

//import std.conv;
import std.file;
import std.path;

import utils;
import dlsbuffer;


class MainForm
{
	WindowManager wm;
	Shell   shell;
	
	string selectDirectoryPath;
	
	this(string arg) {
		wm = new WindowManager("dwt base.");
		
		shell = wm.getShell();
		shellSetLayout();
		
		wm.setMenu();
		
		setDirectoryPath(arg);
		
		createComponents();
		
		wm.run();
	}
	bool checkDirectory(string d) {
		bool result = true;
		if (d.length <= 0) {
			result = false;
		} else if (!d.exists()) {
			result = false;
		} else if (!d.isDir()) {
			result = false;
		}
/*		 else {
			string[] baddir = [
				"C:\\Recovery",
				"C:\\System Volume Infomation",
			];
			foreach (v ; baddir) {
				if (v == d) {
					result = false;
					break;
				}
			}
		}
*/
		return result;
	}
	void setDirectoryPath(string newdir) {
		if (newdir !is null && checkDirectory(newdir)) {
			selectDirectoryPath = buildNormalizedPath(newdir);
		} else {
			selectDirectoryPath = getcwd();
		}
		shell.setText(selectDirectoryPath);
	}
	void updateFolder() {
		setDirectoryPath(dirComboBox.getText());
		setFolder(selectDirectoryPath);
		reloadFileTable(selectDirectoryPath);
		dirComboBox.setText(selectDirectoryPath);
	}
	
	void shellSetLayout() {
		// shell.setLayout(new GridLayout(1, false));
		GridLayout shelllayout = new GridLayout();
		shelllayout.numColumns   = 1;
		shelllayout.marginHeight = 0;
		shelllayout.marginWidth  = 0;
		shell.setLayout(shelllayout);
	}
	Composite createComposit(int col, int gdata) {
		// container Composite
		Composite container = new Composite(shell, SWT.NONE);
		
		// container.setLayout(new GridLayout(col, false));
		GridLayout layout = new GridLayout();
		layout.numColumns   = col;
		layout.marginHeight = 3;
		layout.marginWidth  = 4;
		container.setLayout(layout);
		
		container.setLayoutData(new GridData(gdata));
		return container;
	}
	void createComponents() {
		//
		createDirEditView();
		
		SashForm sashForm = new SashForm(shell, SWT.NONE);
		sashForm.setOrientation(SWT.HORIZONTAL);
		GridData gridData = new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL);
		gridData.horizontalSpan = 2;
		sashForm.setLayoutData(gridData);
		createTreeView(sashForm);
		createTableView(sashForm);
		sashForm.setWeights([ 2, 5 ]);

		Label numObjectsLabel;
		numObjectsLabel = new Label(shell, SWT.BORDER);
		gridData = new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_FILL);
//		gridData.widthHint = 185;
		numObjectsLabel.setLayoutData(gridData);

//		Label diskSpaceLabel;
//		diskSpaceLabel = new Label(shell, SWT.BORDER);
//		gridData = new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_FILL);
//		gridData.horizontalSpan = 2;
//		diskSpaceLabel.setLayoutData(gridData);
	}
	//----------------------
	Combo dirComboBox;
	void createDirEditView() {
		Composite container = createComposit(2, GridData.FILL_HORIZONTAL);
		dirComboBox = new Combo(container, SWT.NONE);
		dirComboBox.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		dirComboBox.setText(selectDirectoryPath);
		dirComboBox.addKeyListener(new class KeyListener {
			override void keyPressed(KeyEvent e) {
				if (e.keyCode == SWT.CR) {
					updateFolder();
				}
			}
			override void keyReleased(KeyEvent e) {
			}
	    });
	    //
		Button updir = wm.createButton(container, "←", SWT.PUSH,  40);
		void onSelection_updir(SelectionEvent e) {
			string newdir = buildNormalizedPath(dirName(dirComboBox.getText()));
			if (newdir != dirComboBox.getText()) {
				dirComboBox.setText(newdir);
				updateFolder();
			}
		}
		updir.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_updir)
		);
	/*	
		Button enter = wm.createButton(container, "↲", SWT.PUSH,  40);
		void onSelection_enter(SelectionEvent e) {
			updateFolder();
		}
		updir.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_enter)
		);
	*/
	}
//----------------------
	Label treeScopeLabel;
	Tree  dirTree;
	void createTreeView(Composite parent) {
		Composite composite = new Composite(parent, SWT.NONE);
		GridLayout gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		gridLayout.marginHeight = gridLayout.marginWidth = 2;
		gridLayout.horizontalSpacing = gridLayout.verticalSpacing = 0;
		composite.setLayout(gridLayout);

//		treeScopeLabel = new Label(composite, SWT.BORDER);
//		treeScopeLabel.setText("AllFolders");
//		treeScopeLabel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_FILL));
		
		dirTree = new Tree(composite, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE);
		dirTree.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));

		dirTree.addListener(SWT.MouseDown, new class Listener {
			void handleEvent(Event event) {
				Point point = new Point(event.x, event.y);
				auto item = cast(dirTreeItem)dirTree.getItem(point);
				if (item !is null) {
					dlog("MouseDown: ", item.getfullPath());
					reloadFileTable(item.getfullPath());
				}
			}
		});
		dirTree.addListener(SWT.MouseDoubleClick, new class Listener {
			void handleEvent(Event event) {
				Point point = new Point(event.x, event.y);
				auto item = cast(dirTreeItem)dirTree.getItem(point);
				if (item !is null) {
					dlog("MouseDoubleClick: ", item.getfullPath());
					dirComboBox.setText(item.getfullPath());
					updateFolder();
				}
			}
		});
		dirTree.addTreeListener(new class TreeAdapter {
			override void treeExpanded(TreeEvent event) {
				dlog("treeExpanded");
				TreeItem item = cast(TreeItem) event.item;
				dirTree.setSelection(item);
				foreach(v ; item.getItems()) {
					v.dispose();
				}
				dirTreeItem ditem = cast(dirTreeItem)item;
				ditem.nodeAddPath();
			}
/*
			override void treeCollapsed(TreeEvent event) {
				dlog("treeCollapsed");
			}
*/
		});
		
//		createTreeDragSource(dirTree);
//		createTreeDropTarget(dirTree);
		setFolder(selectDirectoryPath);
	}
	
	void setFolder(string path) {
		if (dirTree !is null) {
			dirTree.removeAll();
			dirTreeItem item = new dirTreeItem(dirTree, path, SWT.NONE);
			item.nodeAddPath();
			item.setExpanded(true);
		}
	}
	
	class dirTreeItem : TreeItem
	{
		private string fullPath;
		
		this(dirTreeItem parentItem, int style) {
			super(parentItem, style);
		}
		this(Tree parent, string topFullPath, int style) {
			super(parent, style);
			setText(topFullPath);
			fullPath = topFullPath;
		}
		string getfullPath() {
			return fullPath;
		}
		void nodeAddPath() {
			try {
				foreach (DirEntry d; dirEntries(fullPath, SpanMode.shallow)) {
					if (d.isDir()) {
						addChildPath(this, d.name);
					}
				}
			}
			catch (Exception e) {
				dlog("Exception: ", e.toString());
			}
		}
/*
		dirTreeItem setPath(string path) {
			dirTreeItem item = new dirTreeItem(this, SWT.NULL);
			item.addPath(path);
			return item;
		}
*/
		dirTreeItem setPath(dirTreeItem node, string path) {
			dirTreeItem item = new dirTreeItem(node, SWT.NULL);
			item.addPath(path);
			return item;
		}
		private void addPath(string path) {
			fullPath = path;
			setText(path[std.string.lastIndexOf(path, "\\") + 1  .. $]);
		}
		private void addChildPath(dirTreeItem node, string path) {
			dirTreeItem rootNode = setPath(node, path);
			try {
				foreach (DirEntry d; dirEntries(path, SpanMode.shallow)) {
					if (d.isDir()) {
						//  recursive mode
						//	addChildPath(rootNode, d.name);
						setPath(rootNode, d.name);
					}
				}
			}
			catch (Exception e) {
				dlog("Exception: ", e.toString());
			}
		}
version (none) {
		private void addPath(dirTreeItem node, string path) {
			dirTreeItem rootNode = setPath(node, path);
			string[] fnode = scanDirs(path);
			if (fnode.length) {
				// In Directory
				foreach (i; 0 .. fnode.length) {
				//  recursive mode
				//	addPath(rootNode, fnode[i]);
					setPath(rootNode, fnode[i]);
				}
			}
		}
		private string[] scanDirs(string nextDirs) {
			string[] fnode;
			try {
				foreach (DirEntry f; dirEntries(nextDirs, SpanMode.shallow)) {
					if (f.isDir()) {
						fnode ~= f.name;
					}
				}
			}
			catch (Exception e) {
			// ファイルのアクセス権がない場合は Throw されれるので
			// cahchしてこのディレクトリを終了し次のディレクトリを探索
				dlog("Exception: ", e.toString());
			}
			return fnode;
		}
} // version
	}

//----------------------
	Label tableContentsOfLabel;
	Table fileTable;
	void createTableView(Composite parent) {
		Composite composite = new Composite(parent, SWT.NONE);
		GridLayout gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		gridLayout.marginHeight = gridLayout.marginWidth = 2;
		gridLayout.horizontalSpacing = gridLayout.verticalSpacing = 0;
		composite.setLayout(gridLayout);
//		tableContentsOfLabel = new Label(composite, SWT.BORDER);
//		tableContentsOfLabel.setText("Files");
//		tableContentsOfLabel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_FILL));

		//fileTable = new Table(composite, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.FULL_SELECTION);
		fileTable = new Table(composite, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.MULTI | SWT.FULL_SELECTION);
		fileTable.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		
		struct TableTitle { string name; int size; int alignment; }
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
		
/*
		fileTable.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent event) {
				// notifySelectedFiles(getSelectedFiles());
			}

			override void widgetDefaultSelected(SelectionEvent event) {
				// doDefaultFileAction(getSelectedFiles());
			}

			private File[] getSelectedFiles() {
				TableItem[] items = fileTable.getSelection();
				File[] files = new File[items.length];

				for (int i = 0; i < items.length; ++i) {
					files[i] = (File) items[i].getData(TABLEITEMDATA_FILE);
				}
				return files;
			}
		});
*/
		
		setDragDrop(fileTable);
		
		tableItemBackgroundColor = wm.getColor(230, 230, 230);
		
		
		reloadFileTable(selectDirectoryPath);
		setPopup(fileTable);
	}
	
	Color tableItemBackgroundColor;
	uint tableItemcount;
	bool show_directory;
	string tablePath;
	
	void reloadFileTable() {
		if (tablePath !is null) {
			reloadFileTable(tablePath);
		}
	}
	void reloadFileTable(string path) { //, bool show_directory = false) {
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
							// addTable(fileTable, e.name, 0);
						}
					}
					foreach (DirEntry e; dirEntries(path, SpanMode.shallow)) {
						if (e.isFile()) {
							addTable(fileTable, e.name, fileSizeString(e.size), fileDateString(e.name));
							// addTable(fileTable, e.name, e.size);
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
/*
	void addTable(Table node, string filepath, ulong filesize) {
		string name = baseName(filepath);
		string size = fileSizeString(filesize);
		string date = fileDateString(filepath);
		
		string[] fileSpec = [name, size, date];
		fileTableItem item = new fileTableItem(node, SWT.NONE);
		item.setfullPath(filepath);
		item.setText(fileSpec);
	}
*/
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
		addPopupMenu(menu, "extentionOpen", &extentionOpen);
		addPopupMenu(menu, "Popup03", &dg_dummy);
		addPopupMenu(menu, "Popup04", &dg_dummy);
		addMenuSeparator(menu);
		addPopupMenu(menu, "NewFile", &execNewFile);
		auto itemCut   = addPopupMenu(menu, "Cut", &execCut);
		auto itemCopy  = addPopupMenu(menu, "Copy", &execCopy);
		auto itemPasete = addPopupMenu(menu, "Pasete", &execPasete);
		addPopupMenu(menu, "toTrashBox", &execRecycleBin);
		addPopupMenu(menu, "Rename", &execRename);
		addMenuSeparator(menu);
		addPopupMenu(menu, "Delete", &execDelete);
		addPopupMenu(menu, "ReloadAll", &reloadAll);
		addPopupMenu(menu, "ShowDirectory", &toggle_showDirectory, 0, SWT.CHECK);
		
		menu.addMenuListener(new class MenuAdapter {
			override void menuShown(MenuEvent e) {
				// cut & copy menu
				int count = fileTable.getSelectionCount();
				itemCut.setEnabled(count > 0);
				itemCopy.setEnabled(count > 0);
				// is paste valid
				TransferData[] available = wm.clipboard.getAvailableTypes();
				bool enabled = false;
				for (int i = 0; i < available.length; i++) {
					if (FileTransfer.getInstance().isSupportedType(available[i])) {
						enabled = true;
						break;
					}
				}
				itemPasete.setEnabled(enabled);
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
	void extentionOpen() {
		fileTableItem[] items = cast(fileTableItem[]) fileTable.getSelection();
		if (items.length == 1) {
			string file = items[0].getfullPath();
			string ext = extension(file);
			if (ext !is null) {
				dlog("extentonOpen");
				dlog("-file: ", file);
				dlog("-ext: ", ext);
				auto p = Program.findProgram(ext);
				dlog("-command: ", p.command);
				p.execute(file);
			}
		}
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
		}
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
	void execRecycleBin() {
		if (fileTable.getSelectionCount() != 0) {
			auto items = cast(fileTableItem[]) fileTable.getSelection();
			StringBuffer buff = new StringBuffer();
			foreach (v ; items) {
				buff.append(v.getfullPath());
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
//				dlog("GetLastError: ", getLastErrorText());
//				MessageBox.showError(getLastErrorText(), "GetLastError");
			}
			reloadFileTable();
		}
	}
	void execCut() {
	}
	void execCopy() {
	}
	void execPasete() {
	}
	void execRename() {
	}
	void execNewFile() {
		string newFile = tablePath ~ pathDelimiter ~ "newfile.txt";
		std.file.write(tablePath, "// hello");
		updateFolder();
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

	void setDragDrop(Table tt) {
		// windows explorer の仕様
		// drag + SHIFT : DND.DROP_MOVE
		// drag + CTRL  : DND.DROP_COPY
		// drag のみ    : DROP_DEFAULT application default(移動動作)
		// drag + CTRL + SHIFT : DND.DROP_LINK;

		int operations = DND.DROP_COPY;
		// int operations = DND.DROP_MOVE | DND.DROP_COPY;
		//
		DragSource source = new DragSource(tt, operations);
		source.setTransfer([FileTransfer.getInstance()]);
		source.addDragListener(new class DragSourceListener {
			// event.doit = true でドラックできる事をOLEに知らせる
			override void dragStart(DragSourceEvent event) {
				event.doit = (tt.getSelectionCount() != 0);
				dlog("dragStart:event.detail: ", event.detail);
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
			override void dragEnter(DropTargetEvent event) {
				dlog("dragEnter");
				dlog("DropTargetEvent event: ", event);
				// ドラッグ中のマウスカーソルが入ってきた時にdragEnterは呼ばれます
				// ドロップ可能な場合はevent.detail = DND.DROP_COPY に応答を行います
				if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					event.detail = DND.DROP_COPY;
				} else {
					event.detail = DND.DROP_NONE;
				}
				dlog("DropTargetEvent event: ", event);
			}
			override void dragOperationChanged(DropTargetEvent event) {
				// ドラッグ中に修飾キーが押されて処理が変更された時の処理
				// 修飾キーを押さない場合のドラッグ＆ドロップはコピー
				dlog("dragOperationChanged: event: ", event);
				
			}
			override void drop(DropTargetEvent event) {
				// event.data の内容を確認してドロップに対応した処理を行う
				dlog("drop: DropTargetEvent event: ", event);
				if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string[] buff = stringArrayFromObject(event.data);
					dlog("buff: ", buff);
					dlog("tablePath: ", tablePath);
					foreach(v ; buff) {
						CopyFiletoDir(v, tablePath);
					}
					updateFolder();
				}
				dlog("drop: DropTargetEvent event: ", event);
			}
		});
	}
	
}
//-----------------------------------------------------------------------------
void main()
{
	try	{
		dlog("# start");
		import core.runtime: Runtime;
		string arg;
		if (Runtime.args.length >= 2) {
			arg = Runtime.args[1];
		}
		auto main = new MainForm(arg);
	} catch(Exception e) {
		dlog("Exception: ", e.toString());
	}
}
//-----------------------------------------------------------------------------
class WindowManager
{
private:
	Display display;
	Shell   shell;
	Clipboard clipboard;
	Label   statusLine;
	

	void init() {
		if (display is null) {
			display = new Display();
			clipboard = new Clipboard(display);
			display.systemFont = new Font(display, new FontData("Meiryo UI", 10f, SWT.NORMAL));
			//display.systemFont = new Font(display, new FontData("Noto Sans Japanese", 11f, SWT.NORMAL));
			// display.systemFont = new Font(display, new FontData("Consolas", 11f, SWT.NORMAL));
			// display.systemFont = new Font(display, new FontData("Arial", 20, SWT.BOLD));
			
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
		clipboard.dispose();
		display.dispose();
	}
	
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
	
	void createHorizotalLine(Composite c)
    {
        Label line = new Label(c, SWT.SEPARATOR | SWT.HORIZONTAL);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_FILL);
        line.setLayoutData(data);
    }
	
    Composite createRightAlignmentComposite()
    {
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
/**	
	struct SubMenuData {
		string name;
		void delegate() dg;
		int accelerator;
		
		addSubMenu(string m, void delegate() d, int acc);
		
	}
	struct MenuData {
		string name;
		SubMenuData[] submenu;
	}
*/	
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

