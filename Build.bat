@echo off
rem path=C:\D\dmd.2.069.2\windows\bin;C:\D\bin;
path=C:\D\dmd.2.070.0\windows\bin;C:\D\bin;

@echo on

rem dmd -wi -g  cmd_findFile.d dlsbuffer.d
dmd  -g  FileView01.d dlsbuffer.d @dwtlib_normal.txt


@if ERRORLEVEL 1 goto :eof
del *.obj

FileView01 C:\D\rakugaki

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

