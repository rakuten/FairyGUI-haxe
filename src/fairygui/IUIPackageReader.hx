package fairygui;


import openfl.utils.ByteArray;

interface IUIPackageReader
{

    function readDescFile(fileName : String) : String;
    function readResFile(fileName : String) : ByteArray;
}
