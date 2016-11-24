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
    
    public var type : Int;
    public var id : String;
    public var name : String;
    public var width : Int;
    public var height : Int;
    public var file : String;
    public var lastVisitTime : Int;
    
    public var callbacks : Array<Dynamic> = [];
    public var loading : Int;
    public var loaded : Bool;
    
    //image
    public var scale9Grid : Rectangle;
    public var scaleByTile : Bool;
    public var smoothing : Bool;
    public var tileGridIndice : Int;
    public var image : BitmapData;
    
    //movieclip
    public var interval : Float;
    public var repeatDelay : Float;
    public var swing : Bool;
    public var frames : Array<Frame>;
    
    //componenet
    public var componentData : FastXML;
    public var displayList : Array<DisplayListItem>;
    
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
        callbacks.splice(0, -1);
    }
    
    public function toString() : String
    {
        return name;
    }
}
