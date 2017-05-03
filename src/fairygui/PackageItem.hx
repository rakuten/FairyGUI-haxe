package fairygui;

import fairygui.UIPackage;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.media.Sound;

import fairygui.display.Frame;
import fairygui.text.BitmapFont;

class PackageItem
{
    public var owner : UIPackage;
    
    public var type : Int = 0;
    public var id : String;
    public var name : String;
    public var width : Int = 0;
    public var height : Int = 0;
    public var file : String;
    public var lastVisitTime : Int = 0;
    
    public var callbacks : Array<Dynamic> = [];
    public var loading : Int = 0;
    public var loaded : Bool = false;
    
    //image
    public var scale9Grid : Rectangle;
    public var scaleByTile : Bool = false;
    public var smoothing : Bool = false;
    public var tileGridIndice : Int = 0;
    public var image : BitmapData;
    
    //movieclip
    public var interval : Float = 0;
    public var repeatDelay : Float = 0;
    public var swing : Bool = false;
    public var frames : Array<Frame>;
    
    //componenet
    public var componentData : FastXML;
    public var displayList : Array<DisplayListItem>;
    public var extensionType:Class<Dynamic>;
    
    //sound
    public var sound : Sound;
    
    //font
    public var bitmapFont : BitmapFont;
    
    public function new()
    {
    }
    
    public function addCallback(callback :Dynamic) : Void
    {
        var i : Int = Lambda.indexOf(callbacks, callback);
        if (i == -1) 
            callbacks.push(callback);
    }
    
    public function removeCallback(callback :Dynamic) :Dynamic
    {
        var i : Int = Lambda.indexOf(callbacks, callback);
        if (i != -1) 
        {
            callbacks.splice(i, 1);
            return callback;
        }
        else 
        return null;
    }
    
    public function completeLoading() : Void
    {
        loading = 0;
        loaded = true;
        var arr : Array<Dynamic> = callbacks.copy();
        for (callback in arr)
            callback(this);
        callbacks.splice(0, callbacks.length);
    }
    
    public function toString() : String
    {
        return name;
    }
}
