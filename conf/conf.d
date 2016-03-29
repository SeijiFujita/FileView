//
//

import std.stdio;
import std.conv;
import std.json;
import std.exception;

version = USE_BACKUP;

/*
 .hash table(連想配列)を使用してプログラムの内のデータの保存をする
 .ファイルの保存には JSON 形式を使用する
 .JSON には数値を扱う表現があるがシンプルに文字列のみを使用する
 .数値を扱うときはファイルから文字列をロードして改めて数値に変換する

*/

immutable string productName     = "productName";
immutable string productVersion  = "productVersion";
immutable string buildDMD        = "buildDMD";

enum CONFIG_EXT = ".conf";
enum BACKUP_EXT = ".bakup";
enum TEMP_EXT = ".temp";

class Config
{
import std.file;
import std.path;

private:
	string[string] conf;
	string _productPath;
	string _productName;
	string _configFilePath;
	string _configTempPath;
	string _configBackPath;
	
	void init() {
		setConfig(productName, "productName");
		setConfig(productVersion, "ver 0.001a");
		setConfig(buildDMD,  __VENDOR__ ~ " " ~ to!string(__VERSION__));
	}
	
	string getExecPath() {
		import core.runtime: Runtime;
		if (Runtime.args.length <= 0) {
			assert(false, "Runtime.args.length = " ~ to!string(Runtime.args.length));
		}
		return Runtime.args[0].dup;
	}
	
	void setupPath() {
		string appPath = getExecPath();
		_productPath = dirName(appPath); // path/dir/file.ext -> path/dir
		
		version (Windows) {
			_productName = baseName(stripExtension(appPath));
			_configFilePath = stripExtension(appPath) ~ CONFIG_EXT;
		} else {
			_productName = baseName(appPath);
			_configFilePath = appPath ~ CONFIG_EXT;
		}
		_configTempPath = _configFilePath ~ TEMP_EXT;
		_configBackPath = _configFilePath ~ BACKUP_EXT;
    }
	
	void print() {
		writeln("_configFilePath: ", _configFilePath);
		writeln("_configBackPath: ", _configBackPath);
		writeln("_configTempPath: ", _configTempPath);
		writeln("_productPath:    ", _productPath);
		writeln("_productName:    ", _productName);
		writeln("conf: \n", conf);
	}

public:
	this() {
		init();
		setupPath();
		print();
		writeln("#----------------------");
		saveConfig();
	}
	string setConfig(string key, string value) {
		conf[key] = value;
		return value;
	}
	string getConfig(string key) {
		return conf[key];
	}
	int getInt(string key) {
		return to!int(getConfig(key));
	}
version (none) {
	void printcrlf() {
		int n = to!int('\n');
		writefln("\n = %02d, 0x%02X", n, n); // 10
		n = to!int('\r');
		writefln("\r = %02d, 0x%02X", n, n); // 13
	}
}
	// https://ja.wikipedia.org/wiki/JavaScript_Object_Notation
	// のエンコード項目によると
	// JSONのテキストエンコーディングは基本UTF-8 らしい
	//	enum CODE_CR = "\n"; // 10, 0x0A
	//	enum CODE_LF = "\r"; // 13, 0x0D
	//	enum CODE_CRLF = "\n\r"; // 0x0A,0x0D
	//	enum CODE_TAB = "\t"; // HT, 0x09
	string readerbleJson(string json) {
		string result;
		foreach (v ; json) {
			if (v == ',') {
				result ~= ",\n\t";
				continue;
			} else if (v == '{') {
				result ~= "{\n\t";
				continue;
			} else if (v == '}') {
				result ~= "\n";
			}
			result ~= v;
		}
		return result.dup;
	}
	void loadConfig() {
		if (exists(_configFilePath)) {
			JSONValue jroot = parseJSON(cast(string)read(_configFilePath));
			enforce(jroot.type == JSON_TYPE.OBJECT, "jroot.type == JSON_TYPE.OBJECT");
			foreach (string key; conf.keys) {
				setConfig(key, jroot[key].str());
			}
		}
		else {
			saveConfig();
		}
	}
	void exRemove(string f) {
		if (exists(f)) {
			remove(f);
		}
	}
	void exRename(string from, string to) {
		if (exists(from)) {
			exRemove(to);
			rename(from, to);
		}
	}
	void saveConfig() {
		// conf to json
	    JSONValue jroot = ["@config" : "type-01"];	// dummy
		foreach (string key; conf.keys) {
		    jroot.object[key] = getConfig(key);
		}
		
//		string s = readerbleJson(jroot.toString());
//		writeln(s);
		
		exRemove(_configTempPath);
		write(_configTempPath, readerbleJson(jroot.toString()));
version (USE_BACKUP) {
pragma(msg, "USE_BACKUP");
		exRename(_configFilePath, _configBackPath);
		exRename(_configTempPath, _configFilePath);
} else {
		exRename(_configTempPath, _configFilePath);
}
	}
}



void main()
{

	Config conf = new Config;

}

version (none) {
/++
enum JSON_TYPE : byte {
    /// Indicates the type of a $(D JSONValue).
    NULL,
    STRING,  /// ditto
    INTEGER, /// ditto
    UINTEGER,/// ditto
    FLOAT,   /// ditto
    OBJECT,  /// ditto
    ARRAY,   /// ditto
    TRUE,    /// ditto
    FALSE    /// ditto
}
++/
// std.json.d(281)
// private void assign(T)(T arg)

JSON_TYPE jsonType(T)(T arg)
{
	JSON_TYPE result;
	
	static if(is(T : typeof(null))) {
		result = JSON_TYPE.NULL;
	}
	else static if(is(T : string)) {
		result = JSON_TYPE.STRING;
	}
	else static if(is(T : bool)) {
		result = arg ? JSON_TYPE.TRUE : JSON_TYPE.FALSE;
	}
	else static if(is(T : ulong) && isUnsigned!T) {
		result = JSON_TYPE.UINTEGER;
	}
	else static if(is(T : long)) {
		result = JSON_TYPE.INTEGER;
	}
	else static if(isFloatingPoint!T) {
		result = JSON_TYPE.FLOAT;
	}
	else static if(is(T : Value[Key], Key, Value)) {
		static assert(is(Key : string), "AA key must be string");
		result = JSON_TYPE.OBJECT;
	}
	return result;
}
} //

