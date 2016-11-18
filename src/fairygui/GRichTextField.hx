package fairygui;

import fairygui.GTextField;

import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

import fairygui.display.UIRichTextField;
import fairygui.text.RichTextField;
import fairygui.utils.ToolSet;

class GRichTextField extends GTextField
{
    public var ALinkFormat(get, set) : TextFormat;
    public var AHoverFormat(get, set) : TextFormat;

    private var _richTextField : RichTextField;
    
    public function new()
    {
        super();
    }
    
    override private function createDisplayObject() : Void
    {
        _richTextField = new UIRichTextField(this);
        setDisplayObject(_richTextField);
    }
    
    private function get_ALinkFormat() : TextFormat{
        return _richTextField.ALinkFormat;
    }
    
    private function set_ALinkFormat(val : TextFormat) : TextFormat{
        _richTextField.ALinkFormat = val;
        render();
        return val;
    }
    
    private function get_AHoverFormat() : TextFormat{
        return _richTextField.AHoverFormat;
    }
    
    private function set_AHoverFormat(val : TextFormat) : TextFormat{
        _richTextField.AHoverFormat = val;
        render();
        return val;
    }
    
    override private function render() : Void
    {
        renderNow(true);
    }
    
    override private function renderNow(updateBounds : Bool = true) : Void
    {
        if (_heightAutoSize) 
            _richTextField.autoSize = TextFieldAutoSize.LEFT
        else 
        _richTextField.autoSize = TextFieldAutoSize.NONE;
        _richTextField.nativeTextField.filters = _textFilters;
        _richTextField.defaultTextFormat = _textFormat;
        _richTextField.multiline = !_singleLine;
        if (_ubbEnabled) 
            _richTextField.text = ToolSet.parseUBB(_text)
        else 
        _richTextField.text = _text;
        
        var renderSingleLine : Bool = _richTextField.numLines <= 1;
        
        _textWidth = Math.ceil(_richTextField.textWidth);
        if (_textWidth > 0) 
            _textWidth += 5;
        _textHeight = Math.ceil(_richTextField.textHeight);
        if (_textHeight > 0) 
        {
            if (renderSingleLine) 
                _textHeight += 1
            else 
            _textHeight += 4;
        }
        
        if (_heightAutoSize) 
        {
            _richTextField.height = _textHeight + _fontAdjustment;
            
            _updatingSize = true;
            this.height = _textHeight;
            _updatingSize = false;
        }
    }
    
    override private function handleSizeChanged() : Void
    {
        if (!_updatingSize) 
        {
            _richTextField.width = this.width;
            _richTextField.height = this.height + _fontAdjustment;
        }
    }
}

