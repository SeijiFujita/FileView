// Written in the D programming language.
/*
 * dmd 2.070.0 - 2.071.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module bookmark;

import org.eclipse.swt.all;
import java.lang.all;

import std.file;
import std.path;

import conf;
import utils;
import setting;
import dlsbuffer;

class Bookmark
{
	enum  bookmarkTopText = "Bookmark";
	Tree	bookmarkTree;
	Config	bookmarkConf;
	void delegate(string path = null) updateFolder;
	void delegate(string) reloadFileTable;
	
	/*
	string[] loadBookmarkData = [
		"C:\\Home",
		"C:\\D",
		"C:\\D\\rakugaki\\dwtdev",
		"C:\\D\\rakugaki\\DlangUI",
		"C:\\D\\rakugaki\\Gtkd",
	];
	
	struct BookmarkData {
		string _text;
		string _path;
		void set(string text, string path) { _text = text; _path = path; }
		@property void text(string text) { _text = text; }
		@property string text() { return _text; }
		@property void path(string path) { _path = path; }
		@property string path() { return _path; }
	}
	*/
	
	this() {}
	
	void initUI(Composite parent) {
		bookmarkTree = new Tree(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.VIRTUAL);
		bookmarkTree.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		SetTreeViewStyle(bookmarkTree.handle);
		setPopup(bookmarkTree);
		setDrop(bookmarkTree);
		updateBookmark();
		
		bookmarkTree.addListener(SWT.MouseDown, new class Listener {
			void handleEvent(Event event) {
				if (event.button == 1) { // mouse left button
					Point point = new Point(event.x, event.y);
					auto item = cast(bookmarkItem)bookmarkTree.getItem(point);
					if (item !is null) {
						dlog("MouseDown: ", item.getfullPath());
						updateFolder(item.getfullPath());
					}
				}
			}
		});
	}
	
	void updateBookmark() {
		if (bookmarkTree !is null) {
			bookmarkTree.removeAll();
			auto itemTop = new bookmarkItem(bookmarkTree, SWT.NONE);
			string[] bookmarks;
			if (cf.getBookmarks(bookmarks)) {
				foreach (v ; bookmarks) {
					auto item = new bookmarkItem(itemTop, SWT.NONE);
					item.setPath(v);
					// none item.setToolTipText(path);
				}
				itemTop.setExpanded(true);
			}
		}
	}
	void addBookmarkData(string data) {
		if (data.length) {
			string[] bookmarks;
			if (cf.getBookmarks(bookmarks)) {
				bookmarks ~= data;
				cf.setBookmarks(bookmarks);
			}
			else {
				cf.setBookmarks([ data ]);
			}
		}
	}
	
	class bookmarkItem : TreeItem
	{
		string fullPath;
		
		this(bookmarkItem parentItem, int style) {
			super(parentItem, style);
		}
		this(Tree parent, int style) {
			super(parent, style);
			setText(bookmarkTopText);
			fullPath = "";
		}
		this(Tree parent, string path, int style) {
			super(parent, style);
			setText(path);
			fullPath = path;
		}
		string getfullPath() {
			return fullPath;
		}
		void setPath(string path) {
			fullPath = path;
			setText(baseName(path));
		}
		bookmarkItem addChildPath(bookmarkItem node, string path) {
			bookmarkItem item = new bookmarkItem(node, SWT.NULL);
			item.setPath(path);
			return item;
		}
	}
	// Popup Menu
	void setPopup(Tree parent) {
		Menu menu = new Menu(parent);
		parent.setMenu(menu);
		
		addMenuSeparator(menu);
		//--------------------
		addPopupMenu(menu, "BooknarkEditor", &execSettingDialog);
		addPopupMenu(menu, "Delete", &dg_dummy);
		addMenuSeparator(menu);
		addPopupMenu(menu, "Reload", &updateBookmark);
		auto itemDummy = addPopupMenu(menu, "Dummy", &dg_dummy);
		
		menu.addMenuListener(new class MenuAdapter {
			override void menuShown(MenuEvent e) {
				itemDummy.setEnabled(false);
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
	void execSettingDialog() {
		enum BookmarkEditor = 3;
		auto ddlg = new SettingDialog(wm.getShell());
		if (ddlg.open( BookmarkEditor )) {
			updateBookmark();
		}
	}
	
	// Bookmarkの追加の目的の Drop を行う
	//
	void setDrop(Tree tt) {
		int operations = DND.DROP_COPY;
		DropTarget target = new DropTarget(tt, operations);
		target.setTransfer([TextTransfer.getInstance(), FileTransfer.getInstance()]);
		target.addDropListener(new class DropTargetAdapter {
			override void dragEnter(DropTargetEvent event) {
				// ドラッグ中のカーソルが入ってきた時の処理
				// 修飾キーを押さない場合のドラッグ＆ドロップはコピー
				//if (event.detail == DND.DROP_DEFAULT)
				//	event.detail = DND.DROP_COPY;
				dragOperationChanged(event);
			}
			override void dragOperationChanged(DropTargetEvent event) {
				// ドラッグ中に修飾キーが押されて処理が変更された時の処理
				// 修飾キーを押さない場合のドラッグ＆ドロップはコピー
				event.detail = DND.DROP_NONE;
				if (TextTransfer.getInstance().isSupportedType(event.currentDataType)) {
					event.detail = DND.DROP_COPY;
				} else if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					event.detail = DND.DROP_COPY;
				}
			}
			override void drop(DropTargetEvent event) {
				// event.data の内容を確認してカーソル位置にテキストをドロップ
				if (event.data is null) {
					event.detail = DND.DROP_NONE;
				} else if (TextTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string st = stringcast(cast(Object)event.data);
					dlog("drop:TextTransfer: ", st);
					addBookmarkData(st);
					updateBookmark();
				} else if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string[] sar = stringArrayFromObject(event.data);
					foreach(v ; sar) {
						dlog("drop:TextTransfer: ", v);
						addBookmarkData(v);
					}
					updateBookmark();
				}
			}
		});
	}
}
