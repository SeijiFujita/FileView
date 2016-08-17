// Written in the D programming language.
/*
 * dmd 2.070.0 - 2.071.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

/**
debuglog.d
output debuglog


void dlog(...);
void dumplog(void *, uint, string);

Source: dlog.d
License: Distributed under the Boost Software License, Version 1.0.
Authors: Seiji Fujita

Compiler: dmd.2.070.0 / windows


実装済み
------
.dlog は指定された引数をログファイルに出力します。
	dlog(anyValue...);

.dumplog は16進ダンプをログファイルに出力します。
	dumplog(cast(void*)dumpAddress, uint dumpSize, string Comment)

.出力するログのファイル名は実行形式のファイル名に<exeName>_debug_log.txt
.同名のログが存在する場合は追記(append)します。
.

未実装ねた
------
.タイマー機能 ---- 常時起動しているDaemon のログが取れるように
.config.conf を読む事により動作の変更が行える
---- ログ出力のON/OFF
---- ログローテーション--巨大なログを作成しないようにログファイル名を日付け毎に

その他
------
debuglogの名前案
 debug module 
 minilog
 虫眼鏡
 mushiMegane
 Loupe
 magnifying glass 虫眼鏡/拡大鏡の英語
 
 Debug Loupe
 
 debug log system
 DLS
 
 
 
ファイル直接書き版
バッファリングして終了時にディスクに書き込む版

module 名はどうするか？

 debug log system for buffer
 dls.file
 dls.buffer
 dls.console
 dls.window

****/

module dlsbuffer;

import std.string : format, lastIndexOf;
import core.atomic;

//
version = useDebugLog;		/// enable to the debug log
// version = useFilenameAddDATE;	///  Put the date in the filename of the debug log.

/****
Examples:
----
foo() {
 dLog(1, 2.0, '3', "456");

 int count = 0;
 ...
 dLog("count = ", count);
}
----
*/
void dlog(string file = __FILE__, int line = __LINE__, T...)(T args)
{
	version (useDebugLog) {
		dLogMemBuffer._outLogV(format("%s:%d:[%s]", file, line, getDateTimeStr()), args);
		// add getpid
		// dLogMemBuffer._outlogV(format("%s:%d:[%s:%d]", file, line, getDateTimeStr(), getpid()), args);
	}
}

/****
void dlogDump(cast(void *)dumpAddress, uint dumpSize, string Comment);

Examples:
int[10] foo = [0, 1, 2, 3, 4, 5];
dlogDump(cast(void*)&foo, foo.length, "comment");
*/
void dlogDump(string file = __FILE__, int line = __LINE__, T1, T2, T3)(T1 t1, T2 t2, T3 t3)
if (is(T1 == void*) && is(T2 == size_t) && is(T3 == string))
{
	version (useDebugLog) {
		dLogMemBuffer._outLoglf(format("%s:%d:[%s] %s, %d byte", file, line, getDateTimeStr(), t3, t2));
		dLogMemBuffer._dumpLog(t1, t2);
	}
}

/****
void dlogWrite(comment, string Comment);

Examples:
	dlogWrite();
*/
void dlogWrite(string file = __FILE__, int line = __LINE__, T...)(T args)
{
	version (useDebugLog) {
		dLogMemBuffer._outLogV(format("%s:%d:[%s]", file, line, getDateTimeStr()), "#writeLog", args);
		dLogMemBuffer.writeFile();
	}
}

string getDateTimeStr()
{
	import std.datetime;
	SysTime ctime = Clock.currTime();
	const auto fsec = ctime.fracSecs.total!"msecs";
	
	version (Japanese_LocalDateTime_Format) {
		return format(
		           // "%04d/%02d/%02d-%02d:%02d:%02d",
		           "%04d/%02d/%02d-%02d:%02d:%02d.%03d",
		           ctime.year,
		           ctime.month,
		           ctime.day,
		           ctime.hour,
		           ctime.minute,
		           ctime.second,
		           fsec);
	}
	else { // ISO like time format
		return format(
		           // "%04d%02d%02dT%02d%02d%02d",
		           "%04d%02d%02d.%02d%02d%02d.%03d",
		           ctime.year,
		           ctime.month,
		           ctime.day,
		           ctime.hour,
		           ctime.minute,
		           ctime.second,
		           fsec);
	}
}


//
enum string dlog_VERSION = "debuglog.0.2";
enum uint LogBufferSize = 1024;
shared private int threadCounter;
__gshared MemBuffer dLogMemBuffer;

version (useDebugLog)
{
	static this() {
		// synchronized (MemBuffer.classinfo) {
			atomicOp!"+="(threadCounter, 1);
			dLogMemBuffer = MemBuffer.thisGet();
		// }
	}
	//
	static ~this() {
		synchronized (MemBuffer.classinfo) {
			atomicOp!"-="(threadCounter, 1);
			if (threadCounter <= 0) {
				dLogMemBuffer.writeFile();
			}
		}
	}
} // version (useDebugLog)

class MemBuffer {
private:
	this() {}
	static bool instantiated = false;	// static is thread local.
	__gshared MemBuffer instance;		// __gshareg is all grobal.

	shared private bool LogFlag;
	shared private string LogFilename;

	shared string[] _array;
	shared size_t	_count;

	void init() {
		_array.length = LogBufferSize;
		_count = 0;
	}

public:
	void add(string s) {
		synchronized (MemBuffer.classinfo) {
			if (_array.length == count) {
				_array.length *= 2;
			}
			_array[_count] = s.dup;
			atomicOp!"+="(_count, 1);
			// _count++;
		}
	}
	void writeFile() {
		import std.file:append;
		if (_count) {
			foreach (v ; _array) {
				append(LogFilename, v);
			}
			init();
		}
	}
	size_t count() {
		return _count;
	}
//------------------------------------------------
	/**
	void setDebugLog(bool flag = true)
	
	param: flag
	**/
	void setDebugLog(bool flag = true) {
		string ext;
		version (useFilenameAddDATE) {
			ext = "debug_log_" ~ getDateStr() ~ ".txt";
		} else {
			ext = "debug_log.txt";
		}
		
		string execPath;
		import core.runtime: Runtime;
		if (Runtime.args.length) {
			execPath = Runtime.args[0];
		}
		if (execPath.length) {
			auto n = lastIndexOf(execPath, ".");
			if ( n > 0 ) {
				LogFilename = execPath[0 .. n]  ~ "." ~ ext;
			} else {
				LogFilename = execPath ~ "." ~ ext;
			}
		}
		else {
			LogFilename = ext;
		}
		
		LogFlag = flag;
		
		// dlog("#= ", dlog_VERSION, "/", LogFilename, " / ",  __VENDOR__, ":", __VERSION__);
		
		_outLogV(format("%s:%d:[%s]", __FILE__, __LINE__, getDateTimeStr()), 
			"#= ", dlog_VERSION, "/", LogFilename, "/",  __VENDOR__, ":", __VERSION__
			);
	}
	
	void _outLogV(A...)(A args) {
/**
		import std.format : formattedWrite;
		string result;
		void put(const char[] s) { result ~= s; }
		foreach (arg; args) {
			formattedWrite(&put, "%s", arg);
		}
		_outLoglf(result);
**/
		import std.format : formattedWrite;
		import std.array : appender;
		auto w = appender!string();
		foreach (arg; args) {
			formattedWrite(w, "%s", arg);
		}
		 _outLoglf(w.data);
	}
	
	void _outLog(lazy string dg) {
		if (LogFlag) {
			add(dg());
		}
	}

	void _outLoglf(lazy string dg) {
		if (LogFlag) {
			add(dg() ~ "\n");
		}
	}
	
	string getDateStr() {
		import std.datetime;
		SysTime ctime = Clock.currTime();
		return format(
		           "%04d-%02d-%02d",
		           ctime.year,
		           ctime.month,
		           ctime.day);
	}
//
	void _dumpLog(void *Buff, uint byteSize) {
		import std.ascii : isPrintable;
		enum PrintLen = 16;
		ubyte[PrintLen] dumpBuff;
		
		void printCount(uint n) {
			_outLog(format("%06d: ", n));
		}
		void printBody() {
			string s;
			foreach (int i, ubyte v; dumpBuff) {
				if (i == PrintLen / 2) {
					s ~= " ";
				}
				s ~= format("%02X ", v);
			}
			_outLog(s);
		}
		void printAscii() {
			string s;
			char c;
			foreach (ubyte v; dumpBuff) {
				c = cast(char)v;
				if (! isPrintable(c))
					c = '.';
				s ~= format("%c", c);
			}
			_outLoglf(s);
		}
		// Main
		uint endPrint;
		for (uint i; i < byteSize + PrintLen; i += PrintLen) {
			endPrint = i + PrintLen;
			if (byteSize < endPrint) {
				uint end = byteSize - i;
				dumpBuff = dumpBuff.init;
				dumpBuff[0 .. end] = cast(ubyte[]) Buff[i .. byteSize];
				printCount(i);
				printBody();
				printAscii();
				break;
			}
			dumpBuff = cast(ubyte[]) Buff[i .. endPrint];
			printCount(i);
			printBody();
			printAscii();
		}
	}
//------------------------------------------------
// Singleton DCL(dobule Checked Locking)
	static MemBuffer thisGet() {
		if (!instantiated) {
			synchronized (MemBuffer.classinfo) {
				if (instance is null) {
					instance = new MemBuffer;
					instance.init();
					instance.setDebugLog();

				}
				instantiated = true;
			}
		}
		return instance;
	}
} // MemBuffer
/***
http://www.kmonos.net/alang/d/migrate-to-shared.html
http://msystem.m4.coreserver.jp/weblog/?p=1620
https://davesdprogramming.wordpress.com/2013/05/06/low-lock-singletons/

class MySingleton {
  static MySingleton get() {
    if (!instantiated_) {
      synchronized {
        if (instance_ is null) {
          instance_ = new MySingleton;
        }
        instantiated_ = true;
      }
    }
    return instance_;
  }
 private:
  this() {}
  static bool instantiated_;  // Thread local
  __gshared MySingleton instance_;
 }
***/

//eof
