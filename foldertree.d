// Written in the D programming language.
/*
/*
 * dmd 2.070.0 - 2.071.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module foldertree;

import org.eclipse.swt.all;
import java.lang.all;

import std.file;
import std.path;
import std.string;

import utils;
import dlsbuffer;

class FolderTree
{
	Tree  folderTree;
	void delegate(string path = null) updateFolder;
	void delegate(string) reloadFileTable;
	
	void initUI(Composite parent, string path) {
		folderTree = new Tree(parent, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE | SWT.VIRTUAL);
		folderTree.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		setDrag(folderTree);
		SetTreeViewStyle(folderTree.handle);
		reloadFolder(path);
		
//		TableEditor tableEditor = new TableEditor(table);
//		tableEditor.grabHorizontal = true;
		
		folderTree.addListener(SWT.MouseDown, new class Listener {
			void handleEvent(Event event) {
			/*
				1. Click,DoubleClick でtreeExpandedにより干渉する
				2. 結果的に	event.x, event.yはの指し示す位置が操作と不一致になる
				3. folderTree.getSelection() で選択されているitem を対象とるす
				
				Point point = new Point(event.x, event.y);
				auto item = cast(folderTreeItem) folderTree.getItem(point);
				if (item !is null) {
					dlog("MouseDown: ", item.getfullPath());
					dlog("event-x.y : ", event.x, ".", event.y);
					reloadFileTable(item.getfullPath());
				}
			*/
				if (event.button == 1) { // mouse left button
					folderTreeItem[] items = cast(folderTreeItem[])folderTree.getSelection();
					if (items !is null && items.length >= 1) {
						string path = items[0].getfullPath();
						dlog("MouseDown: ", path);
						reloadFileTable(path);
					}
				}
			}
		});
		folderTree.addListener(SWT.MouseDoubleClick, new class Listener {
			void handleEvent(Event event) {
			/*	
				1. Click,DoubleClick でtreeExpandedにより干渉する
				2. 結果的に	event.x, event.yはの指し示す位置が操作と不一致になる
				3. folderTree.getSelection() で選択されているitem を対象とるす
				Point point = new Point(event.x, event.y);
				auto item = cast(folderTreeItem)folderTree.getItem(point);
				if (item !is null) {
					dlog("MouseDoubleClick: ", item.getfullPath());
					dlog("event-x.y : ", event.x, ".", event.y);
					updateFolder(item.getfullPath());
				}
			*/	
				folderTreeItem[] items = cast(folderTreeItem[])folderTree.getSelection();
				// dlog("items.length: ", items.length);
				if (items !is null && items.length >= 1) {
					string path = items[0].getfullPath();
					dlog("MouseDoubleClick: ", path);
					updateFolder(path);
				}
			}
		});
		folderTree.addTreeListener(new class TreeAdapter {
			override void treeExpanded(TreeEvent event) {
				dlog("treeExpanded");
				TreeItem item = cast(TreeItem) event.item;
//				folderTree.setSelection(item);
				foreach(v ; item.getItems()) {
					v.dispose();
				}
				folderTreeItem ditem = cast(folderTreeItem)item;
				ditem.nodeAddPath();
			}
/*
			override void treeCollapsed(TreeEvent event) {
				dlog("treeCollapsed");
			}
*/
		});
		
	}
	
	void reloadFolder(string path) {
		if (folderTree !is null) {
			folderTree.removeAll();
			folderTreeItem item = new folderTreeItem(folderTree, path, SWT.NONE);
			item.nodeAddPath();
			item.setExpanded(true);
		}
	}
	
	class folderTreeItem : TreeItem
	{
		private string fullPath;
		
		this(folderTreeItem parentItem, int style) {
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
				dlog("nodeAddPath: ", fullPath);
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
		
		folderTreeItem setPath(folderTreeItem node, string path) {
			folderTreeItem item = new folderTreeItem(node, SWT.NULL);
			item.addPath(path);
			return item;
		}
		
		private void addPath(string path) {
			fullPath = path;
			setText(path[std.string.lastIndexOf(path, "\\") + 1  .. $]);
		}
		
		private void addChildPath(folderTreeItem pnode, string path) {
			folderTreeItem node = setPath(pnode, path);
			try {
				foreach (DirEntry d; dirEntries(path, SpanMode.shallow)) {
					if (d.isDir()) {
						//	addChildPath(node, d.name);
						setPath(node, d.name);
					}
				}
			}
			catch (Exception e) {
				dlog("Exception: ", e.toString());
			}
		}
	}
	
	void setDrag(Tree tt) {
		//
		int operations = DND.DROP_COPY;
		DragSource source = new DragSource(tt, operations);
		source.setTransfer([TextTransfer.getInstance()]);
		source.addDragListener(new class DragSourceListener {
			// event.doit = true でドラックできる事をOLEに知らせる
			override void dragStart(DragSourceEvent event) {
				dlog("dragStart:event.detail: ", event.detail);
				event.doit = (tt.getSelectionCount() == 1);
			}
			// ドラックするデータを作成し evet.data にセット
			override void dragSetData(DragSourceEvent event) {
				dlog("dragSetData: event.detail: ", event.detail);
				auto items = cast(folderTreeItem[]) tt.getSelection();
				event.data = stringcast(items[0].getfullPath());
				event.detail = DND.DROP_COPY;
			}
			// ドロップ後(貼り付け後)の終了処理
			// 移動を行った後はソースを削除しないと移動にならない
			override void dragFinished(DragSourceEvent event) {
				dlog("dragFinished event: ", event);
			}
		});
	}


}

