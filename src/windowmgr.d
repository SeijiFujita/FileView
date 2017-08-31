// Written in the D programming language.
/*
 * dmd 2.070.0 - 2.075.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module windowmgr;

import org.eclipse.swt.all;
import org.eclipse.swt.internal.win32.OS;

import std.file;
import dlsbuffer;

///
static WindowManager wm;

///
void createWindow(string title) {
	auto wm = new WindowManager(title);
}

class WindowManager
{
public Clipboard clipboard;

private:
	Display display;
	Shell   shell;
	Label   statusLine;
	
	void init() {
		if (display is null) {
			display = new Display();
			clipboard = new Clipboard(display);
			display.systemFont = new Font(display, new FontData("Meiryo UI", 10, SWT.NORMAL));
			// display.systemFont = new Font(display, new FontData("Noto Sans Japanese", 12, SWT.NORMAL));
			
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
		imageDispose();
		clipboard.dispose();
		display.dispose();
	}
//-----------------------------------------------------------------------------
// Images
//-----------------------------------------------------------------------------
	Image[] pool_images;
	
	Image image(string filePath) {
		Image img;
		if (filePath !is null && filePath.exists() && filePath.isFile()) {
			img = new Image(display, filePath);
			pool_images ~= img;
		}
		return img;
	}
	void imageDispose() {
		if (pool_images.length) {
			foreach (v ; pool_images) {
				v.dispose();
			}
		}
	}
	void beep() {
		display.beep();
	}
//-----------------------------------------------------------------------------
// Load Window Resouce
// http://www.nda.co.jp/memo/iconscale/
// http://home.att.ne.jp/banana/akatsuki/doc/mfc/mfc10/
//-----------------------------------------------------------------------------
	static const int IDL_ICON = 100;

	Image loadIcon() {
		//loadIcon
		// int cx = OS.GetSystemMetrics(OS.SM_CXSMICON);  // スモールアイコンの幅
		// int cy = OS.GetSystemMetrics(OS.SM_CYSMICON);  // スモールアイコンの高さ
		// auto hIcon = OS.LoadImage(null, cast(wchar*)IDL_ICON, OS.IMAGE_ICON, 0, 0, OS.LR_SHARED);
		auto hIcon = OS.LoadIcon(OS.GetModuleHandle(null), cast(const wchar*)IDL_ICON);
		return Image.win32_new(null, SWT.ICON, hIcon);
	}


//-----------------------------------------------------------------------------
//  Color
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
	///
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

	///
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
	
	Label setStatusLine(Composite parent) {
		Label statusLine = new Label(parent,  SWT.BORDER /+ SWT.NONE +/);
		statusLine.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
		return statusLine;
	}
	
	void createHorizotalLine(Composite parent) {
        Label line = new Label(parent, SWT.SEPARATOR | SWT.HORIZONTAL);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_FILL);
        line.setLayoutData(data);
    }
	
	///
    Composite createRightAlignmentComposite(Composite parent) {
		enum int BUTTON_WIDTH = 70;
		enum int HORIZONTAL_SPACING = 3;
		enum int MARGIN_WIDTH = 0;
		enum int MARGIN_HEIGHT = 2;
        
        Composite c = new Composite(parent, SWT.NONE);
        GridLayout layout = new GridLayout(2, false);
        layout.horizontalSpacing = HORIZONTAL_SPACING;
        layout.marginWidth = MARGIN_WIDTH;
        layout.marginHeight = MARGIN_HEIGHT;
        c.setLayout(layout);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_END);
        c.setLayoutData(data);
        return c;
    }

	/// text widget 
	Text createText(Composite parent) {
		Text tt = new Text(parent, SWT.MULTI | SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL);
		GridData layoutData = new GridData(GridData.FILL_BOTH);
		tt.setLayoutData(layoutData);
		// set ScrollBar
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
		tt.addListener(SWT.Resize, scrollBarListener);
		tt.addListener(SWT.Modify, scrollBarListener);
		setDragDrop(tt);
		return tt;
	}
	void setDragDrop(Text tt) {
		import java.lang.all: stringcast, stringArrayFromObject;
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


