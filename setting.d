// Written in the D programming language.
/*
/*
 * dmd 2.070.0 - 2.071.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module setting;

import org.eclipse.swt.all;
import java.lang.all;

import conf;
import dlsbuffer;


class SettingDialog : Dialog
{
private:
	Shell shell;
	bool  dialogResult;

public:
	this(Shell parent) {
		super(parent, checkStyle(parent, SWT.APPLICATION_MODAL));
	}
	bool open() {
		
		createContents();
		
		setCenterWindow();
		
		shell.open();
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch())
				display.sleep();
		}
		return dialogResult;
	}
	void setCenterWindow() {
		Display display = getParent().getDisplay();
		Rectangle displayRect = display.getBounds();
		Rectangle shellRect   = shell.getBounds();
		
		int x = (displayRect.width  - shellRect.width) / 2;
		int y = (displayRect.height - shellRect.height) / 2;
		shell.setLocation(x, y);
	}
	Composite createComposit(int col, int gdata) {
		// container Composite
		Composite container = new Composite(shell, SWT.NONE);
		
		// container.setLayout(new GridLayout(col, false));
		GridLayout layout = new GridLayout();
		layout.numColumns   = col;
		layout.marginHeight = 1;
		layout.marginWidth  = 1;
		container.setLayout(layout);
		
		container.setLayoutData(new GridData(gdata));
		return container;
	}
	void createContents() {
		shell = new Shell(getParent(), getStyle() | SWT.DIALOG_TRIM | SWT.RESIZE);
		shell.setSize(400, 500);
		shell.setText("Select Directory");
		shell.setLayout(new GridLayout(1, false));
		
		//
		Composite container = createComposit(1, GridData.FILL_BOTH);
		CTabFolder tabFolder = new CTabFolder(container, SWT.BORDER);
		tabFolder.setLayoutData(new GridData(GridData.FILL_BOTH));
		
		setGeneralTab(tabFolder);
		setTreeviewTab(tabFolder);
		setFileTableTab(tabFolder);
		setBookmarkTab(tabFolder);
		setAboutTab(tabFolder);
		//
		createBottmWidget();
	}
	void setGeneralTab(CTabFolder tabFolder) {
		CTabItem tabItem = new CTabItem(tabFolder, SWT.NONE);
		tabItem.setText("General");
		//
		Composite container = createComposit(tabFolder, 1, GridData.FILL_BOTH);
		//
		createLabel(container, "General:");
		//
		tabItem.setControl(container);
	}
	void setTreeviewTab(CTabFolder tabFolder) {
		CTabItem tabItem = new CTabItem(tabFolder, SWT.NONE);
		tabItem.setText("Treeview");
		//
		Composite container = createComposit(tabFolder, 1, GridData.FILL_BOTH);
		//
		createLabel(container, "Treeview:");
		//
		tabItem.setControl(container);
	}
	void setFileTableTab(CTabFolder tabFolder) {
		CTabItem tabItem = new CTabItem(tabFolder, SWT.NONE);
		tabItem.setText("FileTable");
		//
		Composite container = createComposit(tabFolder, 1, GridData.FILL_BOTH);
		//
		createLabel(container, "FileTable:");
		//
		tabItem.setControl(container);
	}

	Composite createComposit(Composite parent, int col, int gdata) {
		// container Composite
		Composite container = new Composite(parent, SWT.NONE);
		// container.setLayout(new GridLayout(col, false));
		GridLayout layout = new GridLayout();
		layout.numColumns   = col;
		layout.marginHeight = 1;
		layout.marginWidth  = 2;
		container.setLayout(layout);
		
		container.setLayoutData(new GridData(gdata));
		return container;
	}

	void setAboutTab(CTabFolder tabFolder) {
		CTabItem tabItem = new CTabItem(tabFolder, SWT.NONE);
		tabItem.setText("About");
		//
		Composite container = createComposit(tabFolder, 1, GridData.FILL_BOTH);
		//
		createLabel(container, "

 FileView for Windows
 version 0.1a
 
 
 
 URL:
 * https://github.com/SeijiFujita/FileView
 
 LICENCE:
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 
"
		);
		//
		tabItem.setControl(container);
	}
	
	
	void setBookmarkTab(CTabFolder tabFolder) {
		CTabItem tabItem = new CTabItem(tabFolder, SWT.NONE);
		tabItem.setText("Bookmark");
		//
		Composite container = createComposit(tabFolder, 1, GridData.FILL_BOTH);
		//
		createLabel(container, "BookmarkEditor:");
		//
		createText(container);
		loadBookmarkData();
		//
		tabItem.setControl(container);
	}
	
	Text bookmarkText;
	
	void loadBookmarkData() {
		string[] bd;
		if (cf.getBookmarks(bd)) {
			foreach (v ; bd) {
				bookmarkText.append(v ~ bookmarkText.getLineDelimiter());
			}
		}
	}
	void saveBookmarkData() {
		import std.array;
		string tm = bookmarkText.getText();
		if (tm.length > 0) {
			string[] bm = split(tm, bookmarkText.getLineDelimiter());
			if (bm.length > 0) {
				string[] bd;
				foreach (v ; bm) {
					if (v.length >= 3) { // "c:\\"
						bd ~= v;
						dlog("save:bookmark: ", v);
					}
				}
				if (bd.length > 0) {
					cf.setBookmarks(bd);
				} else {
					cf.BookmarksDataClear();
				}
			}
		}
	}
	void createText(Composite parent) {
		bookmarkText = new Text(parent, SWT.MULTI | SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL);
		GridData layoutData = new GridData(GridData.FILL_BOTH);
		bookmarkText.setLayoutData(layoutData);
		Listener scrollBarListener = new class Listener {
			override void handleEvent(Event event) {
				Text t = cast(Text)event.widget;
				Rectangle r1 = t.getClientArea();
				Rectangle r2 = t.computeTrim(r1.x, r1.y, r1.width, r1.height);
				Point p = t.computeSize(SWT.DEFAULT,  SWT.DEFAULT,  true);
				t.getHorizontalBar().setVisible(r2.width <= p.x);
				t.getVerticalBar().setVisible(r2.height <= p.y);
				if (event.type == SWT.Modify) {
					t.getParent().layout(true);
					t.showSelection();
				}
			}
		};
		bookmarkText.addListener(SWT.Resize, scrollBarListener);
		bookmarkText.addListener(SWT.Modify, scrollBarListener);
		setDragDrop(bookmarkText);
	}
	void setDragDrop(Text tt) {
		int operations = DND.DROP_MOVE | DND.DROP_COPY | DND.DROP_LINK;

		DragSource source = new DragSource(tt, operations);
		source.setTransfer([TextTransfer.getInstance()]);
		source.addDragListener(new class DragSourceListener {
			override void dragStart(DragSourceEvent event) {
				event.doit = (tt.getSelectionCount() != 0);
			}
			override void dragSetData(DragSourceEvent event) {
				//	event.data = new ArrayWrapperString(tt.getSelectionText());
				event.data = stringcast(tt.getSelectionText());
			}
			override void dragFinished(DragSourceEvent event) {
				if (event.detail == DND.DROP_MOVE) {
					// ;
				}
			}
		});
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
					tt.insert(st);
				} else if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string[] sar = stringArrayFromObject(event.data);
					foreach(v ; sar) {
						tt.insert(v ~ tt.getLineDelimiter());
					}
				}
			}
		});
	}

//-----------------------------------------
	void createBottmWidget() {
		createHorizotalLine(shell);
		// ok, cancel bottom
		Composite bottom = createRightAlignmentComposite();
		Button okBtn = createButton(bottom, SWT.PUSH, "OK", BUTTON_WIDTH);
		void onSelection_okBtn(SelectionEvent e) {
			dialogResult = true;
			
			saveBookmarkData();
			
			shell.close();
		}
		okBtn.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_okBtn)
		);
		
		Button cancelBtn = createButton(bottom, SWT.PUSH, "キャンセル", BUTTON_WIDTH);
		void onSelection_canselBtn(SelectionEvent e) {
			dialogResult = false;
			shell.close();
		}
		cancelBtn.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_canselBtn)
		);
	}

	enum BUTTON_WIDTH = 70;
	enum HORIZONTAL_SPACING = 3;
	enum MARGIN_WIDTH = 0;
	enum MARGIN_HEIGHT = 2;
    Label createHorizotalLine(Composite c)
    {
        Label line = new Label(c, SWT.SEPARATOR | SWT.HORIZONTAL);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_FILL);
        line.setLayoutData(data);
        return line;
    }
	
    Composite createRightAlignmentComposite()
    {
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
	
	Button createButton(Composite c, int style, string name, int minWidth)
	{
		Button b = new Button(c, style);
		b.setText(name);
		
		GridData d = new GridData();
		int w = b.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		if (w < minWidth) {
			d.widthHint = minWidth;
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
}

