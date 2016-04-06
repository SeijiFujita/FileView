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


import dlsbuffer;

class Bookmark
{
	enum  bookmarkTopText = "Bookmark";
	Tree  bookmarkTree;
	void delegate(string) updateFolder;
	void delegate(string) reloadFileTable;
	
	string[] defaultBookmarks = [
		"C:\\Home",
		"C:\\D",
		"C:\\D\\rakugaki\\dwtdev",
		"C:\\D\\rakugaki\\DlangUI",
		"C:\\D\\rakugaki\\Gtkd",
	];
	
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
//						reloadFileTable(path);
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
//						dirComboBox.setText(item.getfullPath());
//						updateFolder();
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
}
