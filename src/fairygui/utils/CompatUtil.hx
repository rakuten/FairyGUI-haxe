package fairygui.utils;
/**
 * AS3兼容性工具
 **/
class CompatUtil {
    public function new() {

    }

    /**
     * Runtime value of MAX_VALUE depends on target platform
     */
    public static var MAX_VALUE(get, never):Float;
    static inline function get_MAX_VALUE():Float {
        #if flash
        return untyped __global__['Number'].MAX_VALUE;
        #elseif js
        return untyped __js__('Number.MAX_VALUE');
        #elseif cs
        return untyped __cs__('double.MaxValue');
        #elseif java
        return untyped __java__('Double.MAX_VALUE');
        #elseif cpp
        return 1.79769313486232e+308;
//        #elseif python
//        return PythonSysAdapter.float_info.max;
        #else
        return 1.79e+308;
        #end
    }

    /**
     * Runtime value of MIN_VALUE depends on target platform
     */
    public static var MIN_VALUE(get, never):Float;
    static inline function get_MIN_VALUE():Float {
        #if flash
        return untyped __global__['Number'].MIN_VALUE;
        #elseif js
        return untyped __js__('Number.MIN_VALUE');
        #elseif cs
        return untyped __cs__('double.MinValue');
        #elseif java
        return untyped __java__('Double.MIN_VALUE');
        #elseif cpp
        return 2.2250738585072e-308;
//        #elseif python
//        return PythonSysAdapter.float_info.min;
        #else
        return -1.79E+308;
        #end
    }

    public static var INT_MAX_VALUE(get, never):Int;
    static inline function get_INT_MAX_VALUE():Int {
        #if flash
        return untyped __global__['int'].MAX_VALUE;
        #elseif js
        return untyped __js__('Number.MAX_SAFE_INTEGER');
        #elseif cs
        return untyped __cs__('int.MaxValue');
        #elseif java
        return untyped __java__('Integer.MAX_VALUE');
        #elseif cpp
        return 2147483647;
//        #elseif python
//        return PythonSysAdapter.maxint;
        #elseif php
        return untyped __php__('PHP_INT_MAX');
        #else
        return 2^31-1;
        #end
    }

    /**
     * Runtime value of INT_MIN_VALUE depends on target platform
     */
    public static var INT_MIN_VALUE(get, never):Int;
    static inline function get_INT_MIN_VALUE():Int {
        #if flash
        return untyped __global__['int'].MIN_VALUE;
        #elseif js
        return untyped __js__('Number.MIN_SAFE_INTEGER');
        #elseif cs
        return untyped __cs__('int.MinValue');
        #elseif java
        return untyped __java__('Integer.MIN_VALUE');
        #elseif cpp
        return -2147483648;
//        #elseif python
//        return -PythonSysAdapter.maxint - 1;
        #elseif php
        return untyped __php__('PHP_INT_MIN');
        #else
        return -2^31;
        #end
    }

    /** he largest representable 32-bit unsigned integer. */
    inline public static var UINT_MAX_VALUE:UInt = 0xffffffff;

    static public #if !cs inline #end function toFixed(value:Float, digits:Int):String
    {
        #if (js || flash)
        return untyped value.toFixed(digits);
        #elseif php
        return untyped __call__("number_format", value, digits, ".", "");
        #elseif java
        return untyped __java__("String.format({0}, {1})", '%.${digits}f', value);
        #elseif cs
        var separator:String = untyped __cs__('System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator');
        untyped __cs__('System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator = ""');
        var result = untyped value.ToString("N" + digits);
        untyped __cs__('System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator = separator');
        return result;
        #else
        if(digits < 0 || digits > 20)
            throw 'toFixed have a range of 0 to 20. Specified value is not within expected range.';

        var b = Math.pow(10, digits);
        var s = Std.string(value);
        var dotIndex = s.indexOf('.');
        if(dotIndex >= 0) {
            var diff = digits - (s.length - (dotIndex + 1));
            if(diff > 0) {
                s = StringTools.rpad(s, "0", s.length + diff);
            } else {
                s = Std.string(Math.round(value * b) / b);
            }
        } else {
            s += ".";
            s = StringTools.rpad(s, "0", s.length + digits);
        }
        return s;
        #end
    }

    public static var supportsCursor(get,null):Bool;
    static private function get_supportsCursor():Bool
    {
        #if flash
        var result:Bool = flash.ui.Mouse.supportsCursor;
        #else
        var result:Bool = false;
        #end
        return result;
    }

    static public function getTimer():UInt
    {
        return Math.round(haxe.Timer.stamp() * 1000);
    }


}
