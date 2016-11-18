package fairygui.display;


import fairygui.GObject;

interface UIDisplayObject
{
    
    var owner(get, never) : GObject;

}
