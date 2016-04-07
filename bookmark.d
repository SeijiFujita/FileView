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
		bookmarkConf = new Config;
	}
	
	void initUI(Composite parent) {
		bookmarkTree = new Tree(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.VIRTUAL);
		bookmarkTree.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		
		bookmarkView();
		
		bookmarkTree.addListener(SWT.MouseDown, new class Listener {
			void handleEvent(Event event) {
				Point point = new Point(event.x, event.y);
				auto item = cast(bookmarkItem)bookmarkTree.getItem(point);
				if (item !is null) {
					dlog("MouseDown: ", item.getfullPath());
					string path = item.getfullPath();
					if (path.length && path.isDir()) {
						reloadFileTable(path);
					}
				}
			}
		});
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
	// bookmark は Bookmarkの追加の目的の Drop を行う
	void setDrop(Tree tt) {
		int operations = DND.DROP_COPY;
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
			override void dragOperationChanged(DropTargetEvent event) {
				dlog("dragOperationChanged: event: ", event);
				
			}
			override void drop(DropTargetEvent event) {
				// event.data の内容を確認してドロップに対応した処理を行う
				dlog("drop: DropTargetEvent event: ", event);
				if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string[] buff = stringArrayFromObject(event.data);
					dlog("buff: ", buff);
/*				
					if (buff.length >= 1 && checkCopy(buff[0], tablePath)) {
						foreach(v ; buff) {
							CopyFiletoDir(v, tablePath);
						}
						updateFolder();
					}
*/
				}
				dlog("drop: DropTargetEvent event: ", event);
			}
		});
	}

}
