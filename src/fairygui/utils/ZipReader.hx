package fairygui.utils;


import String;
import openfl.utils.ByteArray;
import openfl.utils.Endian;




class ZipReader
{
    private var _stream : ByteArray;
    private var _entries : Map<String, ZipEntry>;
    
    public function new(ba : ByteArray)
    {
        _stream = ba;
        _stream.endian = Endian.LITTLE_ENDIAN;
        _entries = new Map<String, ZipEntry>();
        
        readEntries();
    }

    private function readEntries() : Void{

        _stream.position = _stream.length - 22;
        var buf : ByteArray = new ByteArray();
        buf.endian = Endian.LITTLE_ENDIAN;
        _stream.readBytes(buf, 0, 22);
        buf.position = 10;
        var entryCount : Int = buf.readUnsignedShort();
        buf.position = 16;
        _stream.position = buf.readUnsignedInt();
        buf.clear();

        for (i in 0...entryCount){
            _stream.readBytes(buf, 0, 46);
            buf.position = 28;
            var len : Int = buf.readUnsignedShort();
            var name : String = _stream.readUTFBytes(len);
            var len2 : Int = buf.readUnsignedShort() + buf.readUnsignedShort();
            _stream.position += len2;
            var lastChar : String = name.charAt(name.length - 1);
            if (lastChar == "/" || lastChar == "\\")
                continue;

            name = name.split("\\").join("/");
//            var regexp:EReg = new EReg("\\", "g");
//            name = regexp.replace(name, "/");
            var e : ZipEntry = new ZipEntry();
            e.name = name;
            buf.position = 10;
            e.compress = buf.readUnsignedShort();
            buf.position = 16;
            e.crc = buf.readUnsignedInt();
            e.size = buf.readUnsignedInt();
            e.sourceSize = buf.readUnsignedInt();
            buf.position = 42;
            e.offset = buf.readUnsignedInt() + 30 + len;

            _entries[name] = e;
        }
    }
    
    public function getEntryData(n : String) : ByteArray{
        var entry : ZipEntry = _entries[n];
        if (entry == null) 
            return null;
        
        var ba : ByteArray = new ByteArray();
        if (entry.size < 1)
            return ba;
        
        _stream.position = entry.offset;
        _stream.readBytes(ba, 0, entry.size);
        if (entry.compress > 0)
            ba.inflate();
        
        return ba;
    }
}



class ZipEntry
{
    public var name : String;
    public var offset : Int;
    public var size : Int;
    public var sourceSize : Int;
    public var compress : Int;
    public var crc : Int;
    
    public function new()
    {
    }
}