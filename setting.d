// Written in the D programming language.
/*
 * dmd 2.070.0
 *
 */

module setting;

import org.eclipse.swt.all;

import dlsbuffer;


class SettingDialog : Dialog
{
private:
	Shell shell;
    string selectDirectoryPath;
	bool  dialogResult;

public:
	this(Shell parent) {
		super(parent, checkStyle(parent, SWT.APPLICATION_MODAL));
	}
	string open() {
		createContents();
		shell.open();
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch())
				display.sleep();
		}
		if (dialogResult) {
			return selectDirectoryPath;
		}
		return null;
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
		
		// 1つめのタブアイテムを作成
		CTabItem tabItem1 = new CTabItem(tabFolder, SWT.NONE);
		tabItem1.setText("Tab 1");
		
		Label label1 = new Label(tabFolder,SWT.NONE);
		label1.setText("Label 1");
		tabItem1.setControl(label1);
		
		// 2つめのタブアイテムを作成
		CTabItem tabItem2 = new CTabItem(tabFolder,SWT.NONE);
		tabItem2.setText("Tab 2");
		
		Label label2 = new Label(tabFolder,SWT.NONE);
		label2.setText("Label2");
		tabItem2.setControl(label2);

		// 3つめのタブアイテムを作成
		CTabItem tabItem3 = new CTabItem(tabFolder,SWT.NONE);
		tabItem3.setText("Tab 3");
		
		Label label3 = new Label(tabFolder,SWT.NONE);
		label3.setText("Label 3");
		tabItem3.setControl(label3);
		
		createBottmWidget();
	}


//-----------------------------------------
	void createBottmWidget() {
		createHorizotalLine(shell);
		// ok, cancel bottom
		Composite bottom = createRightAlignmentComposite();
		Button okBtn = createButton(bottom, SWT.PUSH, "OK", BUTTON_WIDTH);
		void onSelection_okBtn(SelectionEvent e) {
			dialogResult = true;
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

