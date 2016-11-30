package fairygui;

import fairygui.ZipUIPackageReader;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.LoaderInfo;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import openfl.system.LoaderContext;
import openfl.utils.ByteArray;


import fairygui.display.Frame;
import fairygui.text.BMGlyph;
import fairygui.text.BitmapFont;
import fairygui.utils.GTimers;
import fairygui.utils.ToolSet;


import openfl.display.Loader;
import fairygui.PackageItem;


class UIPackage
{
    public var id(get, never) : String;
    public var name(get, never) : String;
    public var customId(get, set) : String;

    private var _id : String;
    private var _name : String;
    private var _basePath : String;
    private var _items : Array<PackageItem>;
    private var _itemsById : Map<String, PackageItem>;
    private var _itemsByName : Map<String, PackageItem>;
    private var _customId : String;
    
    private var _reader : IUIPackageReader;
    
    @:allow(fairygui)
    private static var _constructing : Int;
    
    private static var _packageInstById : Map<String, UIPackage> = new Map<String, UIPackage>();
    private static var _packageInstByName : Map<String, UIPackage> = new Map<String, UIPackage>();
    private static var _bitmapFonts : Map<String, BitmapFont> = new Map<String, BitmapFont>();
    private static var _loadingQueue : Array<Loader> = [];
    private static var _stringsSource : Map<String, Dynamic>;
    
    public function new()
    {
        _items = new Array<PackageItem>();
    }
    
    public static function getById(id : String) : UIPackage
    {
        return _packageInstById[id];
    }
    
    public static function getByName(name : String) : UIPackage
    {
        return _packageInstByName[name];
    }
    
    public static function addPackage(desc : ByteArray, res : ByteArray) : UIPackage
    {
        var pkg : UIPackage = new UIPackage();
        var reader : ZipUIPackageReader = new ZipUIPackageReader(desc, res);
        pkg.create(reader);
        _packageInstById[pkg.id] = pkg;
        _packageInstByName[pkg.name] = pkg;
        return pkg;
    }
    
    public static function addPackage2(reader : IUIPackageReader) : UIPackage
    {
        var pkg : UIPackage = new UIPackage();
        pkg.create(reader);
        _packageInstById[pkg.id] = pkg;
        _packageInstByName[pkg.name] = pkg;
        return pkg;
    }
    
    public static function removePackage(packageId : String) : Void
    {
        var pkg : UIPackage = _packageInstById[packageId];
        pkg.dispose();
        Reflect.deleteField(_packageInstById, pkg.id);

        if (pkg._customId != null)
            Reflect.deleteField(_packageInstById, pkg._customId);

        Reflect.deleteField(_packageInstByName, pkg.name);

    }
    
    public static function createObject(pkgName : String, resName : String, userClass : Dynamic = null) : GObject
    {
        var pkg : UIPackage = getByName(pkgName);
        if (pkg != null) 
            return pkg.createObject2(resName, userClass);

        return null;
    }
    
    public static function createObjectFromURL(url : String, userClass : Dynamic = null) : GObject
    {
        var pi : PackageItem = getItemByURL(url);
        if (pi != null) 
            return pi.owner.internalCreateObject(pi, userClass);

        return null;
    }
    
    public static function getItemURL(pkgName : String, resName : String) : String
    {
        var pkg : UIPackage = getByName(pkgName);
        if (pkg == null) 
            return null;
        
        var pi : PackageItem = pkg._itemsByName[resName];
        if (pi == null) 
            return null;
        
        return "ui://" + pkg.id + pi.id;
    }
    
    public static function getItemByURL(url : String) : PackageItem
    {
        if (ToolSet.startsWith(url, "ui://")) 
        {
            var pkgId : String = url.substr(5, 8);
            var srcId : String = url.substr(13);
            var pkg : UIPackage = getById(pkgId);
            if (pkg != null) 
                return pkg.getItemById(srcId);
        }
        return null;
    }
    
    public static function getBitmapFontByURL(url : String) : BitmapFont
    {
        return Reflect.field(_bitmapFonts, url);
    }
    
    public static function setStringsSource(source : FastXML) : Void
    {
        _stringsSource = new Map<String, Dynamic>();
        var list : FastXMLList = source.node.resolve("string").descendants();
        for (xml in list)
        {
            var key : String = xml.att.name;
            var text : String = Std.string(xml);
            var i : Int = key.indexOf("-");
            if (i == -1) 
                continue;
            
            var key2 : String = key.substr(0, i);
            var key3 : String = key.substr(i + 1);
            var col : Dynamic = Reflect.field(_stringsSource, key2);
            if (col == null) 
            {
                col = { };
                Reflect.setField(_stringsSource, key2, col);
            }
            Reflect.setField(col, key3, text);
        }
    }
    
    public static function loadingCount() : Int
    {
        return _loadingQueue.length;
    }
    
    public static function waitToLoadCompleted(callback :Dynamic) : Void
    {
        GTimers.inst.add(10, 0, checkComplete, callback);
    }
    
    private static function checkComplete(callback :Dynamic) : Void
    {
        if (_loadingQueue.length == 0) 
        {
            GTimers.inst.remove(checkComplete);
            callback();
        }
    }
    
    private function create(reader : IUIPackageReader) : Void
    {
        _reader = reader;
        
        var str : String = _reader.readDescFile("package.xml");
        
//        var ignoreWhitespace : Bool = FastXML.ignoreWhitespace;
//        FastXML.ignoreWhitespace = true;
        var xml : FastXML = FastXML.parse(str);
//        FastXML.ignoreWhitespace = ignoreWhitespace;
        
        _id = xml.att.id;
        _name = xml.att.name;

        var resources : Iterator<FastXML> = xml.node.resolve("resources").elements;
        
        _itemsById = new Map<String, PackageItem>();
        _itemsByName = new Map<String, PackageItem>();
        var pi : PackageItem;
        var cxml : FastXML;
        var arr : Array<String>;
        for (cxml in resources)
        {
            pi = new PackageItem();
            pi.type = PackageItemType.parseType(cxml.name);
            pi.id = cxml.att.id;
            pi.name = cxml.att.name;
            pi.file = try cxml.att.file catch (e:Dynamic) null;
            var sizeStr = try cxml.att.size catch (e:Dynamic) null;
            if (sizeStr != null)
            {
                arr = sizeStr.split(",");
                pi.width = Std.parseInt(arr[0]);
                pi.height = Std.parseInt(arr[1]);
            }
            var _sw8_ = (pi.type);            

            switch (_sw8_)
            {
                case PackageItemType.Image:
                {
                    str = try cxml.att.scale catch(e:Dynamic) null;
                    if (str == "9grid") 
                    {
                        pi.scale9Grid = new Rectangle();
                        str = cxml.att.scale9grid;
                        arr = str.split(",");
                        pi.scale9Grid.x = Std.parseFloat(arr[0]);
                        pi.scale9Grid.y = Std.parseFloat(arr[1]);
                        pi.scale9Grid.width = Std.parseFloat(arr[2]);
                        pi.scale9Grid.height = Std.parseFloat(arr[3]);
                        
                        str = try cxml.att.gridTile catch(e:Dynamic) null;
                        if (str != null) 
                            pi.tileGridIndice = Std.parseInt(str);
                    }
                    else if (str == "tile") 
                    {
                        pi.scaleByTile = true;
                    }
                    str = try cxml.att.smoothing catch(e:Dynamic) null;
                    pi.smoothing = str != "false";
                }
            }
            
            pi.owner = this;
            _items.push(pi);
            _itemsById[pi.id] = pi;
            if (pi.name != null) 
                _itemsByName[pi.name] = pi;
        }
        
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            pi = _items[i];
            if (pi.type == PackageItemType.Font) 
            {
                loadFont(pi);
                _bitmapFonts[pi.bitmapFont.id] = pi.bitmapFont;
            }
        }
    }
    
    public function loadAllImages() : Void
    {
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            var pi : PackageItem = _items[i];
            if (pi.type != PackageItemType.Image || pi.image != null || pi.loading > 0)
                continue;
            
            loadImage(pi);
        }
    }
    
    public function dispose() : Void
    {
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            var pi : PackageItem = _items[i];
            var image : BitmapData = pi.image;
            if (image != null) 
                image.dispose()
            else if (pi.frames != null) 
            {
                var frameCount : Int = pi.frames.length;
                for (j in 0...frameCount){
                    image = pi.frames[j].image;
                    if (image != null) 
                        image.dispose();
                }
            }
            else if (pi.bitmapFont != null) 
            {
                Reflect.deleteField(_bitmapFonts, pi.bitmapFont.id);

                pi.bitmapFont.dispose();
            }
        }
    }
    
    private function get_id() : String
    {
        return _id;
    }
    
    private function get_name() : String
    {
        return _name;
    }
    
    private function get_customId() : String
    {
        return _customId;
    }
    
    private function set_customId(value : String) : String
    {
        if (_customId != null)
            Reflect.deleteField(_packageInstById, _customId);

        _customId = value;
        if (_customId != null) 
            Reflect.setField(_packageInstById, _customId, this);

        return value;
    }
    
    public function createObject2(resName : String, userClass : Dynamic = null) : GObject
    {
        var pi : PackageItem = _itemsByName[resName];
        if (pi != null) 
            return internalCreateObject(pi, userClass)
        else 
        return null;
    }
    
    
    private function internalCreateObject(item : PackageItem, userClass : Dynamic) : GObject
    {
        var g : GObject = null;
        if (item.type == PackageItemType.Component) 
        {
            if (userClass != null) 
            {
                if (Std.is(userClass, Class)) 
                    g = cast(Type.createInstance(userClass, []), GObject);
                else 
                g = cast(userClass, GObject);
            }
            else 
            g = UIObjectFactory.newObject(item);
        }
        else 
        g = UIObjectFactory.newObject(item);
        
        if (g == null) 
            return null;
        
        _constructing++;
        g.packageItem = item;
        g.constructFromResource();
        _constructing--;
        return g;
    }
    
    public function getItemById(itemId : String) : PackageItem
    {
        return _itemsById[itemId];
    }
    
    public function getItemByName(resName : String) : PackageItem
    {
        return _itemsByName[resName];
    }
    
    private function getXMLDesc(file : String) : FastXML
    {
//        var ignoreWhitespace : Bool = FastXML.ignoreWhitespace;
//        FastXML.ignoreWhitespace = true;
        var ret : FastXML = FastXML.parse(_reader.readDescFile(file));
//        FastXML.ignoreWhitespace = ignoreWhitespace;
        return ret;
    }
    
    public function getItemRaw(item : PackageItem) : ByteArray
    {
        return _reader.readResFile(item.file);
    }
    
    public function getImage(resName : String) : BitmapData
    {
        var pi : PackageItem = _itemsByName[resName];
        if (pi != null) 
            return pi.image
        else 
        return null;
    }
    
    public function getComponentData(item : PackageItem) : FastXML
    {
        if (item.componentData == null)
        {
            var xml : FastXML = getXMLDesc(item.id + ".xml");
            
            if (_stringsSource != null) 
            {
                var col : Dynamic = _stringsSource[this.id + item.id];
                if (col != null) 
                    translateComponent(xml, col);
            }
            
            item.componentData = xml;
            
            loadComponentChildren(item);
        }
        
        return item.componentData;
    }
    
    private function loadComponentChildren(item : PackageItem) : Void
    {
        var listNode : FastXML = item.componentData.node.displayList;
        if (listNode != null) 
        {
            var col : Iterator<FastXML> = listNode.elements;
//            var dcnt : Int = col.length();
            item.displayList = new Array<DisplayListItem>();
            var di : DisplayListItem;
            for (cxml in col){
//            for (i in 0...dcnt){
//                var cxml : FastXML = col.get(i);
                var tagName : String = cxml.name;
                var src : String = cxml.att.src;
                if (src != null) 
                {
                    var pkgId : String = cxml.att.pkg;
                    var pkg : UIPackage;
                    if (pkgId != null && pkgId != item.owner.id) 
                        pkg = UIPackage.getById(pkgId)
                    else 
                    pkg = item.owner;
                    
                    var pi : PackageItem = (pkg != null) ? pkg.getItemById(src) : null;
                    if (pi != null) 
                        di = new DisplayListItem(pi, null)
                    else 
                    di = new DisplayListItem(null, tagName);
                }
                else 
                {
                    if (tagName == "text" && cxml.att.input == "true")
                        di = new DisplayListItem(null, "inputtext")
                    else 
                    di = new DisplayListItem(null, tagName);
                }
                
                di.desc = cxml;
                item.displayList.push(di);
            }
        }
        else 
        item.displayList = new Array<DisplayListItem>();
    }
    
    private function translateComponent(xml : FastXML, strings : Map<String,Dynamic>) : Void
    {
        var displayList : Iterator<FastXML> = xml.node.resolve("displayList").elements;
        var value : Dynamic;
        for (cxml in displayList)
        {
            var ename : String = cxml.name;
            var elementId : String = cxml.att.id;
            
            if (cxml.att.resolve("tooltips").length > 0)
            {
                value = strings[elementId + "-tips"];
                if (value != null) 
                    cxml.setAttribute("tooltips", value);
            }
            var items : FastXMLList;
            var j : Int;
            if (ename == "text" || ename == "richtext") 
            {
                value = strings[elementId];
                if (value != null) 
                    cxml.setAttribute("text", value);
                value = strings[elementId + "-prompt"];
                if (value != null) 
                    cxml.setAttribute("prompt", value);
            }
            else if (ename == "list") 
            {
                items = cxml.nodes.item;
                j = 0;
                for (exml in items.iterator())
                {
                    value = strings[elementId + "-" + j];
                    if (value != null) 
                        exml.setAttribute("title", value);
                    j++;
                }
            }
            else if (ename == "component") 
            {
                var dxml : FastXML = cxml.node.Button;
                if (dxml != null) 
                {
                    value = strings[elementId];
                    if (value != null) 
                        dxml.setAttribute("title", value);
                    value = strings[elementId + "-0"];
                    if (value != null) 
                        dxml.setAttribute("selectedTitle", value);
                }
                else 
                {
                    dxml = cxml.node.Label;
                    if (dxml != null) 
                    {
                        value = strings[elementId];
                        if (value != null) 
                            dxml.setAttribute("title", value);
                    }
                    else 
                    {
                        dxml = cxml.node.ComboBox;
                        if (dxml != null) 
                        {
                            value = strings[elementId];
                            if (value != null) 
                                dxml.setAttribute("title", value);
                            
                            items = dxml.nodes.item;
                            j = 0;
                            for (exml in items.iterator())
                            {
                                value = strings[elementId + "-" + j];
                                if (value != null) 
                                    exml.setAttribute("title", value);
                                j++;
                            }
                        }
                    }
                }
            }
        }
    }
    
    public function getSound(item : PackageItem) : Sound
    {
        if (!item.loaded) 
            loadSound(item);
        return item.sound;
    }
    
    public function addCallback(resName : String, callback :Dynamic) : Void
    {
        var pi : PackageItem = _itemsByName[resName];
        if (pi != null) 
            addItemCallback(pi, callback);
    }
    
    public function removeCallback(resName : String, callback :Dynamic) : Void
    {
        var pi : PackageItem = _itemsByName[resName];
        if (pi != null) 
            removeItemCallback(pi, callback);
    }
    
    public function addItemCallback(pi : PackageItem, callback :Dynamic) : Void
    {
        pi.lastVisitTime = Math.round(haxe.Timer.stamp() * 1000);
        if (pi.type == PackageItemType.Image) 
        {
            if (pi.loaded) 
            {
                GTimers.inst.add(0, 1, callback);
                return;
            }
            
            pi.addCallback(callback);
            if (pi.loading > 0)
                return;
            
            loadImage(pi);
        }
        else if (pi.type == PackageItemType.MovieClip) 
        {
            if (pi.loaded) 
            {
                GTimers.inst.add(0, 1, callback);
                return;
            }
            
            pi.addCallback(callback);
            if (pi.loading > 0)
                return;
            
            loadMovieClip(pi);
        }
        else if (pi.type == PackageItemType.Swf) 
        {
            pi.addCallback(callback);
            loadSwf(pi);
        }
        else if (pi.type == PackageItemType.Sound) 
        {
            if (!pi.loaded) 
                loadSound(pi);
            
            GTimers.inst.add(0, 1, callback);
        }
    }
    
    public function removeItemCallback(pi : PackageItem, callback :Dynamic) : Void
    {
        pi.removeCallback(callback);
    }
    
    private function loadImage(pi : PackageItem) : Void
    {
        var ba : ByteArray = _reader.readResFile(pi.file);
        var loader : PackageItemLoader = new PackageItemLoader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, __imageLoaded);
        loader.loadBytes(ba);
        
        loader.item = pi;
        pi.loading = 1;
        _loadingQueue.push(loader);
    }
    
    private function __imageLoaded(evt : Event) : Void
    {
        var loader : PackageItemLoader = cast(cast(evt.currentTarget, LoaderInfo).loader, PackageItemLoader);
        var i : Int = Lambda.indexOf(_loadingQueue, loader);
        if (i == -1) 
            return;
        
        _loadingQueue.splice(i, 1);
        
        var pi : PackageItem = loader.item;
        pi.image = cast(loader.content, Bitmap).bitmapData;
        pi.completeLoading();
    }
    
    private function loadSwf(pi : PackageItem) : Void
    {
        var ba : ByteArray = _reader.readResFile(pi.file);
        var loader : PackageItemLoader = new PackageItemLoader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, __swfLoaded);
        var context : LoaderContext = new LoaderContext();
        context.allowCodeImport = true;
        loader.loadBytes(ba, context);
        
        loader.item = pi;
        _loadingQueue.push(loader);
    }
    
    private function __swfLoaded(evt : Event) : Void
    {
        var loader : PackageItemLoader = cast((cast(evt.currentTarget, LoaderInfo).loader), PackageItemLoader);
        var i : Int = Lambda.indexOf(_loadingQueue, loader);
        if (i == -1) 
            return;
        
        _loadingQueue.splice(i, 1);
        
        var pi : PackageItem = loader.item;
        var callback :Dynamic = pi.callbacks.pop();
        if (callback != null) 
            callback(loader.content);
    }
    
    private function loadMovieClip(item : PackageItem) : Void
    {
        var xml : FastXML = getXMLDesc(item.id + ".xml");
        var str : String;
        var arr : Array<Dynamic>;
        str = xml.att.interval;
        if (str != null) 
            item.interval = Std.parseInt(str);
        str = xml.att.swing;
        if (str != null) 
            item.swing = str == "true";
        str = xml.att.repeatDelay;
        if (str != null) 
            item.repeatDelay = Std.parseInt(str);
        
        var frameCount : Int = Std.parseInt(xml.att.frameCount);
        item.frames = new Array<Frame>();
        var frameNodes : FastXMLList = xml.node.resolve("frames").descendants();
        for (i in 0...frameCount-1){
            var frame : Frame = new Frame();
            var frameNode : FastXML = frameNodes.get(i);
            str = frameNode.att.rect;
            arr = str.split(",");
            frame.rect = new Rectangle(Std.parseInt(arr[0]), Std.parseInt(arr[1]), Std.parseInt(arr[2]), Std.parseInt(arr[3]));
            str = frameNode.att.addDelay;
            if (str != null)
                frame.addDelay = Std.parseInt(str);
            item.frames[i] = frame;
            
            if (frame.rect.width == 0) 
                continue;
            
            str = frameNode.att.sprite;
            if (str != null) 
                str = item.id + "_" + str + ".png"
            else 
            str = item.id + "_" + i + ".png";
            var ba : ByteArray = _reader.readResFile(str);
            if (ba != null) 
            {
                var loader : FrameLoader = new FrameLoader();
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, __frameLoaded);
                loader.loadBytes(ba);
                
                loader.item = item;
                loader.frame = frame;
                _loadingQueue.push(loader);
                item.loading++;
            }
        }
    }
    
    private function __frameLoaded(evt : Event) : Void
    {
        var loader : FrameLoader = cast cast(evt.currentTarget, LoaderInfo).loader;
        var i : Int = Lambda.indexOf(_loadingQueue, loader);
        if (i == -1) 
            return;
        
        _loadingQueue.splice(i, 1);
        
        var pi : PackageItem = loader.item;
        var frame : Frame = loader.frame;
        frame.image = cast((loader.content), Bitmap).bitmapData;
        pi.loading--;
        if (pi.loading == 0) 
            pi.completeLoading();
    }
    
    private function loadSound(item : PackageItem) : Void
    {
        var sound : Sound = new Sound();
        var ba : ByteArray = _reader.readResFile(item.file);
        sound.loadCompressedDataFromByteArray(ba, ba.length);
        item.sound = sound;
        item.loaded = true;
    }
    
    private function loadFont(item : PackageItem) : Void
    {
        var font : BitmapFont = new BitmapFont();
        font.id = "ui://" + this.id + item.id;
        var str : String = _reader.readDescFile(item.id + ".fnt");
        
        var lines : Array<Dynamic> = str.split("\n");
        var lineCount : Int = lines.length;
        var i : Int;
        var kv : Dynamic = {};
        var ttf : Bool = false;
        var size : Int = 0;
        var xadvance : Int = 0;
        var resizable : Bool = false;
        var colored : Bool = false;
        var lineHeight : Int = 0;
        var bg : BMGlyph = null;
        for (i in 0...lineCount){
            str = lines[i];
            if (str.length == 0) 
                continue;
            
            str = ToolSet.trim(str);
            var arr : Array<String> = str.split(" ");
            for (j in 1...arr.length){
                var arr2 : Array<String> = arr[j].split("=");
                Reflect.setField(kv, arr2[0], arr2[1]);
            }
            
            str = arr[0];

            if (str == "char") 
            {
                bg = new BMGlyph();
                bg.x = kv.x;
                bg.y = kv.y;
                bg.offsetX = kv.xoffset;
                bg.offsetY = kv.yoffset;
                bg.width = kv.width;
                bg.height = kv.height;
                bg.advance = kv.xadvance;
                bg.channel = font.translateChannel(kv.chnl);
                
                if (!ttf) 
                {
                    if (kv.img) 
                    {
                        var charImg : PackageItem = _itemsById[kv.img];
                        if (charImg != null) 
                        {
                            bg.imageItem = charImg;
                            bg.width = charImg.width;
                            bg.height = charImg.height;
                            loadImage(charImg);
                        }
                    }
                }
                
                if (ttf) 
                    bg.lineHeight = lineHeight
                else 
                {
                    if (bg.advance == 0) 
                    {
                        if (xadvance == 0) 
                            bg.advance = bg.offsetX + bg.width
                        else 
                        bg.advance = xadvance;
                    }
                    bg.lineHeight = (bg.offsetY < 0) ? bg.height : (bg.offsetY + bg.height);
                    if (size > 0 && bg.lineHeight < size) 
                        bg.lineHeight = size;
                }
                
                font.glyphs[String.fromCharCode(kv.id)] = bg;
            }
            else if (str == "info") 
            {
                ttf = kv.face != null;
                colored = ttf;
                size = kv.size;
                resizable = kv.resizable == "true";
                if (kv.colored != null) 
                    colored = kv.colored == "true";
                if (ttf) 
                {
                    var ba : ByteArray = _reader.readResFile(item.id + ".png");
                    var loader : PackageItemLoader = new PackageItemLoader();
                    loader.contentLoaderInfo.addEventListener(Event.COMPLETE, __fontAtlasLoaded);
                    loader.loadBytes(ba);
                    
                    loader.item = item;
                    _loadingQueue.push(loader);
                }
            }
            else if (str == "common") 
            {
                lineHeight = kv.lineHeight;
                if (size == 0) 
                    size = lineHeight
                else if (lineHeight == 0) 
                    lineHeight = size;
                xadvance = kv.xadvance;
            }
        }
        
        if (size == 0 && bg != null)
            size = bg.height;
        
        font.ttf = ttf;
        font.size = size;
        font.resizable = resizable;
        font.colored = colored;
        item.bitmapFont = font;
    }
    
    private function __fontAtlasLoaded(evt : Event) : Void
    {
        var loader : PackageItemLoader = cast((cast((evt.currentTarget), LoaderInfo).loader), PackageItemLoader);
        var i : Int = Lambda.indexOf(_loadingQueue, loader);
        if (i == -1) 
            return;
        
        _loadingQueue.splice(i, 1);
        
        var pi : PackageItem = loader.item;
        pi.bitmapFont.atlas = cast((loader.content), Bitmap).bitmapData;
    }
}




class PackageItemLoader extends Loader
{
    public function new()
    {
        super();
    }
    public var item : PackageItem;
}

class FrameLoader extends Loader
{
    public function new()
    {
        super();
    }
    
    public var item : PackageItem;
    public var frame : Frame;
}
