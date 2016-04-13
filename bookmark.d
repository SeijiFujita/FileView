// Written in the D programming language.
/*
 * dmd 2.070.0
 *
 */

module bookmark;

import org.eclipse.swt.all;
import java.lang.all;

import std.file;
import std.path;

import conf;
import dlsbuffer;

class Bookmark
{
	enum  bookmarkTopText = "Bookmark";
	Tree	bookmarkTree;
	Config	bookmarkConf;
	void delegate(string) updateFolder;
	void delegate(string) reloadFileTable;
	
	string[] defaultBookmarks = [
		"C:\\Home",
		"C:\\D",
		"C:\\D\\rakugaki\\dwtdev",
		"C:\\D\\rakugaki\\DlangUI",
		"C:\\D\\rakugaki\\Gtkd",
	];
	
	this() {
		
	}
	
	void initUI(Composite parent) {
		bookmarkTree = new Tree(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.VIRTUAL);
		bookmarkTree.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		setPopup(bookmarkTree);
		setDrop(bookmarkTree);
		bookmarkView();
		
		bookmarkTree.addListener(SWT.MouseDown, new class Listener {
			void handleEvent(Event event) {
				if (event.button == 1) { // mouse left button
					Point point = new Point(event.x, event.y);
					auto item = cast(bookmarkItem)bookmarkTree.getItem(point);
					if (item !is null) {
						dlog("MouseDown: ", item.getfullPath());
						string path = item.getfullPath();
						if (path.length && path.isDir()) {
							// reloadFileTable(path);
							updateFolder(item.getfullPath());
						}
					}
				}
			}
		});
version (none) {
		bookmarkTree.addListener(SWT.MouseDoubleClick, new class Listener {
			void handleEvent(Event event) {
				Point point = new Point(event.x, event.y);
				auto item = cast(bookmarkItem)bookmarkTree.getItem(point);
				if (item !is null) {
					dlog("MouseDoubleClick: ", item.getfullPath());
					string path = item.getfullPath();
					if (path.length && path.isDir()) {
						updateFolder(item.getfullPath());
					}
				}
			}
		});
} // version
	}
	
	void bookmarkView() {
		if (bookmarkTree !is null) {
			bookmarkTree.removeAll();
			auto itemTop = new bookmarkItem(bookmarkTree, SWT.NONE);
			foreach (v ; defaultBookmarks) {
				auto item = new bookmarkItem(itemTop, SWT.NONE);
				item.setPath(v);
			}
			itemTop.setExpanded(true);
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
		addPopupMenu(menu, "BooknarkEditor", &dg_dummy);
		addPopupMenu(menu, "Delete", &dg_dummy);
		addMenuSeparator(menu);
		addPopupMenu(menu, "Reload", &bookmarkView);
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

	// Bookmarkの追加の目的の Drop を行う
	//
	void setDrop(Tree tt) {
		int operations = DND.DROP_COPY;
		DropTarget target = new DropTarget(tt, operations);
		target.setTransfer([TextTransfer.getInstance()]);
		target.addDropListener(new class DropTargetAdapter {
			// ドラッグ中のマウスカーソルが入ってきた時にdragEnterが呼ばれます
			// ドロップ可能な場合はevent.detail = DND.DROP_COPY で応答を行います
			override void dragEnter(DropTargetEvent event) {
				dlog("dragEnter");
				dlog("DropTargetEvent event: ", event);
				if (TextTransfer.getInstance().isSupportedType(event.currentDataType)) {
					event.detail = DND.DROP_COPY;
				} else {
					event.detail = DND.DROP_NONE;
				}
				dlog("DropTargetEvent event: ", event);
			}
			// ドラッグ中に修飾キーが押されて処理が変更された時の処理
			override void dragOperationChanged(DropTargetEvent event) {
				dlog("dragOperationChanged: event: ", event);
				
			}
			override void drop(DropTargetEvent event) {
				// event.data の内容を確認してドロップに対応した処理を行う
				dlog("drop: DropTargetEvent event: ", event);
				if (event.data !is null) {
					string st = stringcast(cast(Object)event.data);
					defaultBookmarks ~= st;
					bookmarkView();
				}
			}
		});
	}

}
