@echo off
rem path=C:\D\dmd.2.069.2\windows\bin;C:\D\bin;
rem path=C:\D\dmd.2.070.2\windows\bin;C:\D\bin;
path=C:\D\dmd.2.071.1\windows\bin;C:\D\bin;

@echo on

rem dmd @dwtlib_normal.txt
dmd @dwt64lib_normal.txt


@if ERRORLEVEL 1 goto :eof
del *.obj

rem FileView01 C:\D\rakugaki
FileView64

echo done...
goto :eof
-----------------------------------
C:\D\dwt\UI-examples\sdi\Tree>dfmt --help 
dfmt 0.3.5

Options:
    --help | -h            Print this help message
    --inplace              Edit files in place

Formatting Options:
    --align_switch_statements
    --brace_style
    --end_of_line
    --help|h
    --indent_size
    --indent_style|t
    --inplace
    --soft_max_line_length
    --max_line_length
    --outdent_attributes
    --outdent_labels
    --space_after_cast
    --split_operator_at_line_end

-----------------------------------
DMD32 D Compiler v2.070.2
Copyright (c) 1999-2015 by Digital Mars written by Walter Bright

Documentation: http://dlang.org/
Config file: C:\D\dmd.2.070.2\windows\bin\sc.ini
Usage:
  dmd files.d ... { -switch }

  files.d        D source files
  @cmdfile       read arguments from cmdfile
  -allinst       generate code for all template instantiations
  -betterC       omit generating some runtime information and helper functions
  -boundscheck=[on|safeonly|off]   bounds checks on, in @safe only, or off
  -c             do not link
  -color[=on|off]   force colored console output on or off
  -conf=path     use config file at path
  -cov           do code coverage analysis
  -cov=nnn       require at least nnn% code coverage
  -D             generate documentation
  -Dddocdir      write documentation file to docdir directory
  -Dffilename    write documentation file to filename
  -d             silently allow deprecated features
  -dw            show use of deprecated features as warnings (default)
  -de            show use of deprecated features as errors (halt compilation)
  -debug         compile in debug code
  -debug=level   compile in debug code <= level
  -debug=ident   compile in debug code identified by ident
  -debuglib=name    set symbolic debug library to name
  -defaultlib=name  set default library to name
  -deps          print module dependencies (imports/file/version/debug/lib)
  -deps=filename write module dependencies to filename (only imports)
  -dip25         implement http://wiki.dlang.org/DIP25 (experimental)
  -g             add symbolic debug info
  -gc            add symbolic debug info, optimize for non D debuggers
  -gs            always emit stack frame
  -gx            add stack stomp code
  -H             generate 'header' file
  -Hddirectory   write 'header' file to directory
  -Hffilename    write 'header' file to filename
  --help         print help and exit
  -Ipath         where to look for imports
  -ignore        ignore unsupported pragmas
  -inline        do function inlining
  -Jpath         where to look for string imports
  -Llinkerflag   pass linkerflag to link
  -lib           generate library rather than object files
  -m32           generate 32 bit code
  -m32mscoff     generate 32 bit code and write MS-COFF object files
  -m64           generate 64 bit code
  -main          add default main() (e.g. for unittesting)
  -man           open web browser on manual page
  -map           generate linker .map file
  -noboundscheck no array bounds checking (deprecated, use -boundscheck=off)
  -O             optimize
  -o-            do not write object file
  -odobjdir      write object & library files to directory objdir
  -offilename    name output file to filename
  -op            preserve source path for output files
  -profile       profile runtime performance of generated code
  -profile=gc    profile runtime allocations
  -release       compile release version
  -run srcfile args...   run resulting program, passing args
  -shared        generate shared library (DLL)
  -transition=id show additional info about language change identified by 'id'
  -transition=?  list all language changes
  -unittest      compile in unit tests
  -v             verbose
  -vcolumns      print character (column) numbers in diagnostics
  -verrors=num   limit the number of error messages (0 means unlimited)
  -vgc           list all gc allocations including hidden ones
  -vtls          list all variables going into thread local storage
  --version      print compiler version and exit
  -version=level compile in version code >= level
  -version=ident compile in version code identified by ident
  -w             warnings as errors (compilation will halt)
  -wi            warnings as messages (compilation will continue)
  -X             generate JSON file
  -Xffilename    write JSON file to filename

