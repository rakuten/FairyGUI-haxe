package fairygui;

import fairygui.GComponent;
import fairygui.Transition;
import openfl.errors.Error;

import openfl.events.EventDispatcher;

import fairygui.event.StateChangeEvent;

@:meta(Event(name = "stateChanged", type = "fairygui.event.StateChangeEvent"))

class Controller extends EventDispatcher
{
    public var name(get, set):String;
    public var parent(get, never):GComponent;
    public var selectedIndex(get, set):Int;
    public var previsousIndex(get, never):Int;
    public var selectedPage(get, set):String;
    public var previousPage(get, never):String;
    public var pageCount(get, never):Int;
    public var selectedPageId(get, set):String;
    public var oppositePageId(never, set):String;
    public var previousPageId(get, never):String;

    private var _name:String;
    private var _selectedIndex:Int = 0;
    private var _previousIndex:Int = 0;
    private var _pageIds:Array<Dynamic>;
    private var _pageNames:Array<Dynamic>;
    private var _pageTransitions:Array<PageTransition>;
    private var _playingTransition:Transition;

    @:allow(fairygui)
    private var _parent:GComponent;
    @:allow(fairygui)
    private var _autoRadioGroupDepth:Bool = false;

    private static var _nextPageId:Int = 0;

    public function new()
    {
        super();
        _pageIds = [];
        _pageNames = [];
        _selectedIndex = -1;
        _previousIndex = -1;
    }

    private function get_name():String
    {
        return _name;
    }

    private function set_name(value:String):String
    {
        _name = value;
        return value;
    }

    private function get_parent():GComponent
    {
        return _parent;
    }

    private function get_selectedIndex():Int
    {
        return _selectedIndex;
    }

    private function set_selectedIndex(value:Int):Int
    {
        if (_selectedIndex != value)
        {
            if (value > _pageIds.length - 1)
                throw new Error("index out of bounds: " + value);

            _previousIndex = _selectedIndex;
            _selectedIndex = value;
            _parent.applyController(this);

            this.dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));

            if (_playingTransition != null)
            {
                _playingTransition.stop();
                _playingTransition = null;
            }

            if (_pageTransitions != null)
            {
                for (pt in _pageTransitions)
                {
                    if (pt.toIndex == _selectedIndex && (pt.fromIndex == -1 || pt.fromIndex == _previousIndex))
                    {
                        _playingTransition = parent.getTransition(pt.transitionName);
                        break;
                    }
                }

                if (_playingTransition != null)
                    _playingTransition.play(function():Void{_playingTransition = null;});
            }
        }
        return value;
    }

    //功能和设置selectedIndex一样，但不会触发事件
    public function setSelectedIndex(value:Int):Void
    {
        if (_selectedIndex != value)
        {
            if (value > _pageIds.length - 1)
                throw new Error("index out of bounds: " + value);

            _previousIndex = _selectedIndex;
            _selectedIndex = value;
            _parent.applyController(this);

            if (_playingTransition != null)
            {
                _playingTransition.stop();
                _playingTransition = null;
            }
        }
    }

    private function get_previsousIndex():Int
    {
        return _previousIndex;
    }

    private function get_selectedPage():String
    {
        if (_selectedIndex == -1)
            return null;
        else
            return _pageNames[_selectedIndex];
    }

    private function set_selectedPage(val:String):String
    {
        var i:Int = Lambda.indexOf(_pageNames, val);
        if (i == -1)
            i = 0;
        this.selectedIndex = i;
        return val;
    }

    //功能和设置selectedPage一样，但不会触发事件
    public function setSelectedPage(value:String):Void
    {
        var i:Int = Lambda.indexOf(_pageNames, value);
        if (i == -1)
            i = 0;
        this.setSelectedIndex(i);
    }

    private function get_previousPage():String
    {
        if (_previousIndex == -1)
            return null;
        else
            return _pageNames[_previousIndex];
    }

    private function get_pageCount():Int
    {
        return _pageIds.length;
    }

    public function getPageName(index:Int):String
    {
        return _pageNames[index];
    }

    public function addPage(name:String = ""):Void
    {
        addPageAt(name, _pageIds.length);
    }

    public function addPageAt(name:String, index:Int):Void
    {
        var nid:String = "_" + (_nextPageId++);
        if (index == _pageIds.length)
        {
            _pageIds.push(nid);
            _pageNames.push(name);
        }
        else
        {
            _pageIds.insert(index + 1, nid);
            _pageNames.insert(index + 1, name);
        }
    }

    public function removePage(name:String):Void
    {
        var i:Int = Lambda.indexOf(_pageNames, name);
        if (i != -1)
        {
            _pageIds.splice(i, 1);
            _pageNames.splice(i, 1);
            if (_selectedIndex >= _pageIds.length)
                this.selectedIndex = _selectedIndex - 1;
            else
                _parent.applyController(this);
        }
    }

    public function removePageAt(index:Int):Void
    {
        _pageIds.splice(index, 1);
        _pageNames.splice(index, 1);
        if (_selectedIndex >= _pageIds.length)
            this.selectedIndex = _selectedIndex - 1;
        else
            _parent.applyController(this);
    }

    public function clearPages():Void
    {
        _pageIds.splice(0, _pageIds.length);
        _pageNames.splice(0, _pageNames.length);
        if (_selectedIndex != -1)
            this.selectedIndex = -1;
        else
            _parent.applyController(this);
    }

    public function hasPage(aName:String):Bool
    {
        return Lambda.indexOf(_pageNames, aName) != -1;
    }

    public function getPageIndexById(aId:String):Int
    {
        return Lambda.indexOf(_pageIds, aId);
    }

    public function getPageIdByName(aName:String):String
    {
        var i:Int = Lambda.indexOf(_pageNames, aName);
        if (i != -1)
            return _pageIds[i];
        else
            return null;
    }

    public function getPageNameById(aId:String):String
    {
        var i:Int = Lambda.indexOf(_pageIds, aId);
        if (i != -1)
            return _pageNames[i];
        else
            return null;
    }

    public function getPageId(index:Int):String
    {
        return _pageIds[index];
    }

    private function get_selectedPageId():String
    {
        if (_selectedIndex == -1)
            return null;
        else
            return _pageIds[_selectedIndex];
    }

    private function set_selectedPageId(val:String):String
    {
        var i:Int = Lambda.indexOf(_pageIds, val);
        this.selectedIndex = i;
        return val;
    }

    private function set_oppositePageId(val:String):String
    {
        var i:Int = Lambda.indexOf(_pageIds, val);
        if (i > 0)
            this.selectedIndex = 0;
        else if (_pageIds.length > 1)
            this.selectedIndex = 1;
        return val;
    }

    private function get_previousPageId():String
    {
        if (_previousIndex == -1)
            return null;
        else
            return _pageIds[_previousIndex];
    }

    public function setup(xml:FastXML):Void
    {
        _name = xml.att.name;
        _autoRadioGroupDepth = xml.att.autoRadioGroupDepth == "true";

        var i:Int;
        var k:Int;
        var cnt:Int;
        var arr:Array<String>;
        var str:String = xml.att.pages;
        if (str != null)
        {
            arr = str.split(",");
            cnt = arr.length;
            i = 0;
            while (i < cnt)
            {
                _pageIds.push(arr[i]);
                _pageNames.push(arr[i + 1]);
                i += 2;
            }
        }

        str = xml.att.transitions;
        if (str != null)
        {
            _pageTransitions = new Array<PageTransition>();
            arr = str.split(",");
            cnt = arr.length;
            for (i in 0...cnt)
            {
                str = arr[i];
                if (str == null)
                    continue;

                var pt:PageTransition = new PageTransition();
                k = str.indexOf("=");
                pt.transitionName = str.substr(k + 1);
                str = str.substring(0, k);
                k = str.indexOf("-");
                pt.toIndex = Std.parseInt(str.substring(k + 1));
                str = str.substring(0, k);
                if (str == "*")
                    pt.fromIndex = -1;
                else
                    pt.fromIndex = Std.parseInt(str);
                _pageTransitions.push(pt);
            }
        }

        if (_parent != null && _pageIds.length > 0)
            _selectedIndex = 0;
        else
            _selectedIndex = -1;
    }
}


class PageTransition
{
    public var transitionName:String;
    public var fromIndex:Int;
    public var toIndex:Int;

    public function new()
    {
    }
}
