// Written in the D programming language.
/*
 * dmd 2.070.0 - 2.071.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module main;

import org.eclipse.swt.all;
import java.lang.all;

import std.file;
import std.path;

import foldertree;
import filetable;
import bookmark;
import utils;
import conf;
import setting;
import dlsbuffer;

class MainForm
{
	Shell		shell;
	FolderTree  tfolder;
	FileTable	tfile;
	Bookmark	bookmark;
	Combo		pathEdit;
	string		DirectoryPath;
	
	this() {
		// utils.wm is grobal
		wm = new WindowManager("FileView");
		cf = new Config();
		
		shell = wm.getShell();
		shellSetLayout();
		shell.setImage(wm.loadIcon());
		
		tfolder  = new FolderTree;
		tfile    = new FileTable;
		bookmark = new Bookmark;
		
		setStartupPath();
		createComponents();
		
		tfolder.updateFolder  = &updateFolder;
		tfolder.reloadFileTable  = &tfile.reloadFileTable;
		
		bookmark.updateFolder = &updateFolder;
		bookmark.reloadFileTable = &tfile.reloadFileTable;
		
		tfile.updateFolder    = &updateFolder;
		
		wm.run();
		cf.setLastPath(DirectoryPath);
		cf.saveConfig();
	}
	/*
	string open(string selectdir = null) {
		initUI();
		
		wm.run();
		cf.setString(LastPath, DirectoryPath);
		cf.saveConfig();
		if (dialogResult) {
			return selectDirectoryPath;
		}
		return null;
	}
	*/
	void setStartupPath() {
		string arg = getCommandLine();
		if (arg is null) {
			cf.getLastPath(arg);
		}
		setDirectoryPath(arg);
	}
	string getCommandLine() {
		import core.runtime: Runtime;
		string arg = null;
		if (Runtime.args.length >= 2) {
			arg = Runtime.args[1];
		}
		return arg;
	}
	void setDirectoryPath(string d) {
		if (d !is null && d.length && d.exists()) {
			string path = buildNormalizedPath(d);
			if (path.isFile()) {
				DirectoryPath = dirName(path);
			} else {
				DirectoryPath = path;
			}
			//
		}
		else {
			DirectoryPath = getcwd();
		}
		shell.setText("FileView -" ~ DirectoryPath);
	}
	void updateFolder(string path = null) {
		if (path != null) {
			pathEdit.setText(path);
		}
		setDirectoryPath(pathEdit.getText());
		tfolder.reloadFolder(DirectoryPath);
		tfile.reloadFileTable(DirectoryPath);
		pathEdit.setText(DirectoryPath);
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
		layout.marginHeight = 1;
		layout.marginWidth  = 2;
		container.setLayout(layout);
		
		container.setLayoutData(new GridData(gdata));
		return container;
	}
	void createComponents() {
		//
		pathEditBox();
		
		SashForm sashForm = new SashForm(shell, SWT.NONE);
		sashForm.setOrientation(SWT.HORIZONTAL);
		GridData gridData = new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL);
		gridData.horizontalSpan = 2;
		sashForm.setLayoutData(gridData);
		
		SashForm leftForm = new SashForm(sashForm, SWT.NONE);
		leftForm.setOrientation(SWT.VERTICAL);
		tfolder.initUI(leftForm, DirectoryPath);
		bookmark.initUI(leftForm);
		leftForm.setWeights([ 5, 2 ]);
		
		tfile.initUI(sashForm, DirectoryPath);
		sashForm.setWeights([ 2, 5 ]);
	}
	//----------------------
	void pathEditBox() {
		Composite container = createComposit(3, GridData.FILL_HORIZONTAL);
		// go to root directory bottom
		Button updir = wm.createButton(container, "↑", SWT.PUSH,  35);
		updir.setToolTipText("Go to root direction");
		// updir.setImage(LarrowIcon);
		void onSelection_updir(SelectionEvent e) {
			string newdir = buildNormalizedPath(dirName(pathEdit.getText()));
			if (newdir != pathEdit.getText()) {
				pathEdit.setText(newdir);
				updateFolder();
			}
		}
		updir.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_updir)
		);
		//
		pathEdit = new Combo(container, SWT.NONE);
		pathEdit.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		pathEdit.setText(DirectoryPath);
		pathEdit.addKeyListener(new class KeyListener {
			override void keyPressed(KeyEvent e) {
				if (e.keyCode == SWT.CR) {
					updateFolder();
				}
			}
			override void keyReleased(KeyEvent e) {
			}
	    });
		// setting buttom
		// Button menu = wm.createButton(container, "≡", SWT.PUSH, 35);
		Button menu = wm.createButton(container, "＝", SWT.PUSH, 35);
		menu.setToolTipText("Menu dlalog");
		// menu.setImage(MenuIcon);
		
		void onSelection_menu(SelectionEvent e) {
			openSettingDialog();
		}
		menu.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_menu)
		);
	}
	void openSettingDialog() {
		auto ddlg = new SettingDialog(shell);
		if (ddlg.open()) {
			bookmark.updateBookmark();
		}
	}
}
//-----------------------------------------------------------------------------
void main()
{
	try	{
		dlog("# start");
		auto main = new MainForm();
	}
	catch(Exception e) {
		dlog("Exception: ", e.toString());
	}
}
//-----------------------------------------------------------------------------
