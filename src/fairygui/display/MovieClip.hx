package fairygui.display;

import fairygui.display.PlayState;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;

import fairygui.utils.GTimers;

class MovieClip extends Sprite
{
    public var playState(get, set) : PlayState;
    public var frames(get, set) : Array<Frame>;
    public var frameCount(get, never) : Int;
    public var boundsRect(get, set) : Rectangle;
    public var currentFrame(get, set) : Int;
    public var playing(get, set) : Bool;

    public var interval : Int;
    public var swing : Bool;
    public var repeatDelay : Int;
    
    private var _bitmap : Bitmap;
    private var _playing : Bool;
    private var _playState : PlayState;
    private var _frameCount : Int;
    private var _frames : Array<Frame>;
    private var _currentFrame : Int;
    private var _boundsRect : Rectangle;
    private var _start : Int;
    private var _end : Int;
    private var _times : Int;
    private var _endAt : Int;
    private var _status : Int;  //0-none, 1-next loop, 2-ending, 3-ended  
    private var _callback : Dynamic;
    
    public function new()
    {
        super();
        _bitmap = new Bitmap();
        addChild(_bitmap);
        _playState = new PlayState();
        _playing = true;
        setPlaySettings();
        
        this.addEventListener(Event.ADDED_TO_STAGE, __addedToStage);
        this.addEventListener(Event.REMOVED_FROM_STAGE, __removedFromStage);
    }
    
    private function get_playState() : PlayState
    {
        return _playState;
    }
    
    private function set_playState(value : PlayState) : PlayState
    {
        _playState = value;
        return value;
    }
    
    private function get_frames() : Array<Frame>
    {
        return _frames;
    }
    
    private function set_frames(value : Array<Frame>) : Array<Frame>
    {
        _frames = value;
        if (_frames != null) 
            _frameCount = _frames.length
        else 
        _frameCount = 0;
        
        if (_end == -1 || _end > _frameCount - 1) 
            _end = _frameCount - 1;
        if (_endAt == -1 || _endAt > _frameCount - 1) 
            _endAt = _frameCount - 1;
        
        if (_currentFrame < 0 || _currentFrame > _frameCount - 1) 
            _currentFrame = _frameCount - 1;
        
        _playState.rewind();
        return value;
    }
    
    private function get_frameCount() : Int
    {
        return _frameCount;
    }
    
    private function get_boundsRect() : Rectangle
    {
        return _boundsRect;
    }
    
    private function set_boundsRect(value : Rectangle) : Rectangle
    {
        _boundsRect = value;
        return value;
    }
    
    private function get_currentFrame() : Int
    {
        return _currentFrame;
    }
    
    private function set_currentFrame(value : Int) : Int
    {
        if (_currentFrame != value) 
        {
            _currentFrame = value;
            _playState.currentFrame = value;
            setFrame((_currentFrame < _frameCount) ? _frames[_currentFrame] : null);
        }
        return value;
    }
    
    private function get_playing() : Bool
    {
        return _playing;
    }
    
    private function set_playing(value : Bool) : Bool
    {
        _playing = value;
        
        if (_playing && this.stage != null) 
            GTimers.inst.callBy24Fps(update)
        else 
        GTimers.inst.remove(update);
        return value;
    }
    
    //从start帧开始，播放到end帧（-1表示结尾），重复times次（0表示无限循环），循环结束后，停止在endAt帧（-1表示参数end）
    public function setPlaySettings(start : Int = 0, end : Int = -1, times : Int = 0, endAt : Int = -1, endCallback : Dynamic = null) : Void
    {
        _start = start;
        _end = end;
        if (_end == -1 || _end > _frameCount - 1) 
            _end = _frameCount - 1;
        _times = times;
        _endAt = endAt;
        if (_endAt == -1) 
            _endAt = _end;
        _status = 0;
        _callback = endCallback;
        this.currentFrame = start;
    }
    
    private function update() : Void
    {
        if (_playing && _frameCount != 0 && _status != 3) 
        {
            _playState.update(this);
            if (_currentFrame != _playState.currentFrame) 
            {
                if (_status == 1) 
                {
                    _currentFrame = _start;
                    _playState.currentFrame = _currentFrame;
                    _status = 0;
                }
                //draw
                else if (_status == 2) 
                {
                    _currentFrame = _endAt;
                    _playState.currentFrame = _currentFrame;
                    _status = 3;
                    
                    //play end
                    if (_callback != null) 
                    {
                        var f : Dynamic = _callback;
                        _callback = null;
                        if (f.length == 1) 
                            f(this)
                        else 
                        f();
                    }
                }
                else 
                {
                    _currentFrame = _playState.currentFrame;
                    if (_currentFrame == _end) 
                    {
                        if (_times > 0) 
                        {
                            _times--;
                            if (_times == 0) 
                                _status = 2
                            else 
                            _status = 1;
                        }
                    }
                }
                
                
                
                setFrame(_frames[_currentFrame]);
            }
        }
    }
    
    private function setFrame(frame : Frame) : Void
    {
        if (frame != null) 
        {
            _bitmap.bitmapData = frame.image;
            _bitmap.x = frame.rect.x;
            _bitmap.y = frame.rect.y;
        }
        else 
        _bitmap.bitmapData = null;
    }
    
    private function __addedToStage(evt : Event) : Void
    {
        if (_playing) 
            GTimers.inst.callBy24Fps(update);
    }
    
    private function __removedFromStage(evt : Event) : Void
    {
        GTimers.inst.remove(update);
    }
}

