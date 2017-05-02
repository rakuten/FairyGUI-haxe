package fairygui;

import openfl.filters.BitmapFilter;
import fairygui.ITextColorGear;

import openfl.display.BitmapData;
import openfl.filters.DropShadowFilter;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

import fairygui.display.UIImage;
import fairygui.display.UITextField;
import fairygui.text.BMGlyph;
import fairygui.text.BitmapFont;
import fairygui.utils.CharSize;
import fairygui.utils.FontUtils;
import fairygui.utils.GTimers;
import fairygui.utils.ToolSet;

class GTextField extends GObject implements ITextColorGear
{
    public var font(get, set) : String;
    public var fontSize(get, set) : Int;
    public var color(get, set) : UInt;
    public var align(get, set) : Int;
    public var verticalAlign(get, set) : Int;
    public var leading(get, set) : Int;
    public var letterSpacing(get, set) : Int;
    public var underline(get, set) : Bool;
    public var bold(get, set) : Bool;
    public var italic(get, set) : Bool;
    public var singleLine(get, set) : Bool;
    public var stroke(get, set) : Int;
    public var strokeColor(get, set) : UInt;
    public var shadowOffset(get, set) : Point;
    public var ubbEnabled(get, set) : Bool;
    public var autoSize(get, set) : Int;
    public var textWidth(get, never) : Int;

    private var _ubbEnabled : Bool = false;
    private var _autoSize : Int = 0;
    private var _widthAutoSize : Bool = false;
    private var _heightAutoSize : Bool = false;
    private var _textFormat : TextFormat;
    private var _text : String;
    private var _font : String;
    private var _fontSize : Int = 0;
    private var _align : Int = 0;
    private var _verticalAlign : Int = 0;
    private var _color : Int = 0;
    private var _leading : Int = 0;
    private var _letterSpacing : Int = 0;
    private var _underline : Bool = false;
    private var _bold : Bool = false;
    private var _italic : Bool = false;
    private var _singleLine : Bool = false;
    private var _stroke : Int = 0;
    private var _strokeColor : UInt = 0;
    private var _shadowOffset : Point;
    private var _textFilters : Array<BitmapFilter>;
    
    private var _textField : TextField;
    private var _bitmap : UIImage;
    private var _bitmapData : BitmapData;
    
    private var _updatingSize : Bool = false;
    private var _requireRender : Bool = false;
    private var _sizeDirty : Bool = false;
    private var _textWidth : Int = 0;
    private var _textHeight : Int = 0;
    private var _fontAdjustment : Int = 0;
    
    private var _bitmapFont : BitmapFont;
    private var _lines : Array<LineInfo>;
    
    private static inline var GUTTER_X : Int = 2;
    private static inline var GUTTER_Y : Int = 2;
    
    public function new()
    {
        super();
        
        _textFormat = new TextFormat();
        _fontSize = 12;
        _color = 0;
        _align = AlignType.Left;
        _verticalAlign = VertAlignType.Top;
        _text = "";
        _leading = 3;
        
        _autoSize = AutoSizeType.Both;
        _widthAutoSize = true;
        _heightAutoSize = true;
        updateAutoSize();
    }
    
    override private function createDisplayObject() : Void
    {
        _textField = new UITextField(this);
        _textField.mouseEnabled = false;
        _textField.selectable = false;
        _textField.multiline = true;
        _textField.width = 10;
        _textField.height = 1;
        setDisplayObject(_textField);
    }
    
    private function switchBitmapMode(val : Bool) : Void
    {
        if (val && this.displayObject == _textField) 
        {
            if (_bitmap == null) 
                _bitmap = new UIImage(this);
            switchDisplayObject(_bitmap);
        }
        else if (!val && this.displayObject == _bitmap) 
            switchDisplayObject(_textField);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        if (_bitmapData != null) 
        {
            _bitmapData.dispose();
            _bitmapData = null;
        }
        _requireRender = false;
        _bitmapFont = null;
    }
    
    override private function set_text(value : String) : String
    {
        _text = value;
        if (_text == null) 
            _text = "";
        updateGear(6);
        
        if (parent != null && parent._underConstruct) 
            renderNow();
        else 
            render();
        return value;
    }
    
    override private function get_text() : String
    {
        return _text;
    }
    
    @:final private function get_font() : String
    {
        return _font;
    }
    
    private function set_font(value : String) : String
    {
        if (_font != value) 
        {
            _font = value;
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_fontSize() : Int
    {
        return _fontSize;
    }
    
    private function set_fontSize(value : Int) : Int
    {
        if (value < 0) 
            return 0;
        
        if (_fontSize != value) 
        {
            _fontSize = value;
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_color() : Int
    {
        return _color;
    }
    
    private function set_color(value : Int) : Int
    {
        if (_color != value) 
        {
            _color = value;
            updateGear(4);
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_align() : Int
    {
        return _align;
    }
    
    private function set_align(value : Int) : Int
    {
        if (_align != value) 
        {
            _align = value;
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_verticalAlign() : Int
    {
        return _verticalAlign;
    }
    
    private function set_verticalAlign(value : Int) : Int
    {
        if (_verticalAlign != value) 
        {
            _verticalAlign = value;
            doAlign();
        }
        return value;
    }
    
    @:final private function get_leading() : Int
    {
        return _leading;
    }
    
    private function set_leading(value : Int) : Int
    {
        if (_leading != value) 
        {
            _leading = value;
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_letterSpacing() : Int
    {
        return _letterSpacing;
    }
    
    private function set_letterSpacing(value : Int) : Int
    {
        if (_letterSpacing != value) 
        {
            _letterSpacing = value;
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_underline() : Bool
    {
        return _underline;
    }
    
    private function set_underline(value : Bool) : Bool
    {
        if (_underline != value) 
        {
            _underline = value;
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_bold() : Bool
    {
        return _bold;
    }
    
    private function set_bold(value : Bool) : Bool
    {
        if (_bold != value) 
        {
            _bold = value;
            updateTextFormat();
        }
        return value;
    }
    
    @:final private function get_italic() : Bool
    {
        return _italic;
    }
    
    private function set_italic(value : Bool) : Bool
    {
        if (_italic != value) 
        {
            _italic = value;
            updateTextFormat();
        }
        return value;
    }
    
    private function get_singleLine() : Bool
    {
        return _singleLine;
    }
    
    private function set_singleLine(value : Bool) : Bool
    {
        if (_singleLine != value) 
        {
            _singleLine = value;
            _textField.multiline = !_singleLine;
            if(!_widthAutoSize)
                _textField.wordWrap = !_singleLine;

            if(!_underConstruct)
                render();
        }
        return value;
    }
    
    @:final private function get_stroke() : Int
    {
        return _stroke;
    }
    
    private function set_stroke(value : Int) : Int
    {
        if (_stroke != value) 
        {
            _stroke = value;
            updateTextFilters();
        }
        return value;
    }
    
    @:final private function get_strokeColor() : UInt
    {
        return _strokeColor;
    }
    
    private function set_strokeColor(value : UInt) : UInt
    {
        if (_strokeColor != value) 
        {
            _strokeColor = value;
            updateTextFilters();
            updateGear(4);
        }
        return value;
    }
    
    @:final private function get_shadowOffset() : Point
    {
        return _shadowOffset;
    }
    
    private function set_shadowOffset(value : Point) : Point
    {
        _shadowOffset = value;
        updateTextFilters();
        return value;
    }
    
    private function updateTextFilters() : Void
    {
        if (_stroke != 0 && _shadowOffset != null) 
            _textFilters = [
                new DropShadowFilter(_stroke, 45, _strokeColor, 1, 1, 1, 5, 1), 
                new DropShadowFilter(_stroke, 222, _strokeColor, 1, 1, 1, 5, 1), 
                new DropShadowFilter(Math.sqrt(Math.pow(_shadowOffset.x, 2) + Math.pow(_shadowOffset.y, 2)), 
                Math.atan2(_shadowOffset.y, _shadowOffset.x) * ToolSet.RAD_TO_DEG, _strokeColor, 1, 1, 2)]
        else if (_stroke != 0) 
            _textFilters = [
                new DropShadowFilter(_stroke, 45, _strokeColor, 1, 1, 1, 5, 1), 
                new DropShadowFilter(_stroke, 222, _strokeColor, 1, 1, 1, 5, 1)]
        else if (_shadowOffset != null) 
            _textFilters = [
                new DropShadowFilter(Math.sqrt(Math.pow(_shadowOffset.x, 2) + Math.pow(_shadowOffset.y, 2)), 
                Math.atan2(_shadowOffset.y, _shadowOffset.x) * ToolSet.RAD_TO_DEG, _strokeColor, 1, 1, 2)]
        else 
        _textFilters = null;

        _textField.filters = _textFilters;
    }
    
    private function set_ubbEnabled(value : Bool) : Bool
    {
        if (_ubbEnabled != value) 
        {
            _ubbEnabled = value;
            render();
        }
        return value;
    }
    
    @:final private function get_ubbEnabled() : Bool
    {
        return _ubbEnabled;
    }
    
    private function set_autoSize(value : Int) : Int
    {
        if (_autoSize != value) 
        {
            _autoSize = value;
            _widthAutoSize = value == AutoSizeType.Both;
            _heightAutoSize = value == AutoSizeType.Both || value == AutoSizeType.Height;
            updateAutoSize();
            render();
        }
        return value;
    }
    
    @:final private function get_autoSize() : Int
    {
        return _autoSize;
    }
    
    private function get_textWidth() : Int
    {
        if (_requireRender) 
            renderNow();
        return _textWidth;
    }
    
    override public function ensureSizeCorrect() : Void
    {
        if (_sizeDirty && _requireRender) 
            renderNow();
    }
    
    private function updateTextFormat() : Void
    {
        _textFormat.size = _fontSize;
        if (ToolSet.startsWith(_font, "ui://")) 
        {
            _bitmapFont = UIPackage.getBitmapFontByURL(_font);
            _fontAdjustment = 0;
        }
        else 
        {
            _bitmapFont = null;
            
            if (_font != null) 
                _textFormat.font = _font;
            else 
            _textFormat.font = UIConfig.defaultFont;

            var charSize:Dynamic = CharSize.getSize(Std.int(_textFormat.size), _textFormat.font, _bold);
            _fontAdjustment = charSize.yIndent;

        }
        
        if (this.grayed) 
            _textFormat.color = 0xAAAAAA;
        else 
            _textFormat.color = _color;

        _textFormat.align = AlignType.toString(_align);
        _textFormat.leading = _leading - _fontAdjustment;
        if (_textFormat.leading < 0) 
            _textFormat.leading = 0;

        _textFormat.letterSpacing = _letterSpacing;
        _textFormat.bold = _bold;
        _textFormat.underline = _underline;
        _textFormat.italic = _italic;

        _textField.defaultTextFormat = _textFormat;
        _textField.embedFonts = FontUtils.isEmbeddedFont(_textFormat);


        if (!_underConstruct) 
            render();
    }

    private function updateAutoSize():Void
    {
        if(_widthAutoSize)
        {
            _textField.autoSize = TextFieldAutoSize.LEFT;
            _textField.wordWrap = false;
        }
        else
        {
            _textField.autoSize = TextFieldAutoSize.NONE;
            _textField.wordWrap = !_singleLine;
        }
    }
    
    private function render() : Void
    {
        if (!_requireRender) 
        {
            _requireRender = true;
            GTimers.inst.add(0, 1, __render);
        }
        
        if (!_sizeDirty && (_widthAutoSize || _heightAutoSize)) 
        {
            _sizeDirty = true;
            _dispatcher.dispatch(this, GObject.SIZE_DELAY_CHANGE);
        }
    }
    
    private function __render() : Void
    {
        if (_requireRender) 
            renderNow();
    }
    
    private function renderNow(updateBounds : Bool = true) : Void
    {
        _requireRender = false;
        _sizeDirty = false;
        
        if (_bitmapFont != null) 
        {
            renderWithBitmapFont(updateBounds);
            return;
        }
        
        switchBitmapMode(false);
        var w:Float;
        var h:Float;
        w = this.width;
        if(w!=_textField.width)
            _textField.width = w;
        h = Math.max(this.height, Std.int(_textFormat.size));
        if(h!=_textField.height)
            _textField.height = h;
        
        if (_ubbEnabled) 
            _textField.htmlText = ToolSet.parseUBB(ToolSet.encodeHTML(_text));
        else 
            _textField.text = _text;
        _textField.defaultTextFormat = _textFormat;
        
        var renderSingleLine : Bool = _textField.numLines <= 1;
        
        _textWidth = Math.ceil(_textField.textWidth);
        if (_textWidth > 0) 
            _textWidth += 5;
        _textHeight = Math.ceil(_textField.textHeight);
        if (_textHeight > 0) 
        {
            if (renderSingleLine) 
                _textHeight += 1;
            else 
                _textHeight += 4;
        }
        
        if (_widthAutoSize)
            w = _textWidth;

        if (_heightAutoSize) 
        {
            h = _textHeight;
            if (!_widthAutoSize) 
                _textField.height = _textHeight + _fontAdjustment + 3;
        }
        else 
        {
            h = Std.int(this.height);
            if(_textHeight>h)
                _textHeight = Std.int(h);
            _textField.height = _textHeight + _fontAdjustment + 3;
        }
        
        if (updateBounds) 
        {
            _updatingSize = true;
            this.setSize(w, h);
            _updatingSize = false;
            
            doAlign();
        }
    }
    
    private function renderWithBitmapFont(updateBounds : Bool) : Void
    {
        switchBitmapMode(true);
        _bitmap.filters = _textFilters;

        if (_lines == null) 
            _lines = new Array<LineInfo>();
        else 
            LineInfo.returnList(_lines);
        
        var letterSpacing : Int = _letterSpacing;
        var lineSpacing : Int = _leading - 1;
        var rectWidth : Int = Std.int(this.width - GUTTER_X * 2);
        var lineWidth : Int = 0;
        var lineHeight : Int = 0;
        var lineTextHeight : Int = 0;
        var glyphWidth : Int = 0;
        var glyphHeight : Int = 0;
        var wordChars : Int = 0;
        var wordStart : Int = 0;
        var wordEnd : Int = 0;
        var lastLineHeight : Int = 0;
        var lineBuffer : String = "";
        var lineY : Int = GUTTER_Y;
        var line : LineInfo;
        var wordWrap : Bool = !_widthAutoSize && !_singleLine;
        var fontScale : Float = (_bitmapFont.resizable) ? _fontSize / _bitmapFont.size : 1;
        _textWidth = 0;
        _textHeight = 0;
        
        var textLength : Int = _text.length;
        var glyph : BMGlyph;
        var ch : String;
        for (offset in 0...textLength){
            ch = _text.charAt(offset);
            var cc : Int = ch.charCodeAt(offset);
            
            if (ch == "\n") 
            {
                lineBuffer += ch;
                line = LineInfo.borrow();
                line.width = lineWidth;
                if (lineTextHeight == 0) 
                {
                    if (lastLineHeight == 0) 
                        lastLineHeight = Math.ceil(_fontSize * fontScale);
                    if (lineHeight == 0) 
                        lineHeight = lastLineHeight;
                    lineTextHeight = lineHeight;
                }
                line.height = lineHeight;
                lastLineHeight = lineHeight;
                line.textHeight = lineTextHeight;
                line.text = lineBuffer;
                line.y = lineY;
                lineY += (line.height + lineSpacing);
                if (line.width > _textWidth) 
                    _textWidth = line.width;
                _lines.push(line);
                
                lineBuffer = "";
                lineWidth = 0;
                lineHeight = 0;
                lineTextHeight = 0;
                wordChars = 0;
                wordStart = 0;
                wordEnd = 0;
                continue;
            }
            
            if (cc > 256 || cc <= 32) 
            {
                if (wordChars > 0) 
                    wordEnd = lineWidth;
                wordChars = 0;
            }
            else 
            {
                if (wordChars == 0) 
                    wordStart = lineWidth;
                wordChars++;
            }

            if (ch == " ") 
            {
                glyphWidth = Math.ceil(_fontSize * fontScale / 2);
                glyphHeight = Math.ceil(_fontSize * fontScale);
            }
            else 
            {
                glyph = _bitmapFont.glyphs[ch];
                if (glyph != null)
                {
                    glyphWidth = Math.ceil(glyph.advance * fontScale);
                    glyphHeight = Math.ceil(glyph.lineHeight * fontScale);
                }
                else if (ch == " ") 
                {
                    glyphWidth = Math.ceil(_bitmapFont.size * fontScale / 2);
                    glyphHeight = Math.ceil(_bitmapFont.size * fontScale);
                }
                else 
                {
                    glyphWidth = 0;
                    glyphHeight = 0;
                }
            }
            if (glyphHeight > lineTextHeight) 
                lineTextHeight = glyphHeight;
            
            if (glyphHeight > lineHeight) 
                lineHeight = glyphHeight;
            
            if (lineWidth != 0) 
                lineWidth += letterSpacing;
            lineWidth += glyphWidth;
            
            if (!wordWrap || lineWidth <= rectWidth) 
            {
                lineBuffer += ch;
            }
            else 
            {
                line = LineInfo.borrow();
                line.height = lineHeight;
                line.textHeight = lineTextHeight;
                
                if (lineBuffer.length == 0)   //the line cannt fit even a char  
                {
                    line.text = ch;
                }
                else if (wordChars > 0 && wordEnd > 0)   //if word had broken, move it to new line  
                {
                    lineBuffer += ch;
                    var len : Int = lineBuffer.length - wordChars;
                    line.text = ToolSet.trimRight(lineBuffer.substr(0, len));
                    line.width = wordEnd;
                    lineBuffer = lineBuffer.substr(len + 1);
                    lineWidth -= wordStart;
                }
                else 
                {
                    line.text = lineBuffer;
                    line.width = lineWidth - (glyphWidth + letterSpacing);
                    lineBuffer = ch;
                    lineWidth = glyphWidth;
                    lineHeight = glyphHeight;
                    lineTextHeight = glyphHeight;
                }
                line.y = lineY;
                lineY += (line.height + lineSpacing);
                if (line.width > _textWidth) 
                    _textWidth = line.width;
                
                wordChars = 0;
                wordStart = 0;
                wordEnd = 0;
                _lines.push(line);
            }
        }
        
        if (lineBuffer.length > 0 || _lines.length > 0 && ToolSet.endsWith(_lines[_lines.length - 1].text, "\n")) 
        {
            line = LineInfo.borrow();
            line.width = lineWidth;
            if (lineHeight == 0) 
                lineHeight = lastLineHeight;
            if (lineTextHeight == 0) 
                lineTextHeight = lineHeight;
            line.height = lineHeight;
            line.textHeight = lineTextHeight;
            line.text = lineBuffer;
            line.y = lineY;
            if (line.width > _textWidth) 
                _textWidth = line.width;
            _lines.push(line);
        }
        
        if (_textWidth > 0) 
            _textWidth += GUTTER_X * 2;
        
        var count : Int = _lines.length;
        if (count == 0) 
        {
            _textHeight = 0;
        }
        else 
        {
            line = _lines[_lines.length - 1];
            _textHeight = line.y + line.height + GUTTER_Y;
        }
        
        var w : Int;
        var h : Int;
        if (_widthAutoSize) 
        {
            if (_textWidth == 0) 
                w = 0;
            else 
                w = _textWidth;
        }
        else 
            w = Std.int(this.width);
        
        if (_heightAutoSize) 
        {
            if (_textHeight == 0) 
                h = 0;
            else 
                h = _textHeight;
        }
        else 
            h = Std.int(this.height);
        
        if (updateBounds) 
        {
            _updatingSize = true;
            this.setSize(w, h);
            _updatingSize = false;
            
            doAlign();
        }
        
        if (_bitmapData != null) 
            _bitmapData.dispose();
        
        if (w == 0 || h == 0) 
            return;
        
        _bitmapData = new BitmapData(w, h, true, 0);
        _bitmap.bitmapData = _bitmapData;
        
        var charX : Int = GUTTER_X;
        var lineIndent : Int;
        var charIndent : Int;
        rectWidth = Std.int(this.width - GUTTER_X * 2);
        
        var lineCount : Int = _lines.length;
        for (i in 0...lineCount){
            line = _lines[i];
            charX = GUTTER_X;
            
            if (_align == AlignType.Center) 
                lineIndent = Std.int((rectWidth - line.width) / 2);
            else if (_align == AlignType.Right) 
                lineIndent = rectWidth - line.width;
            else 
                lineIndent = 0;
            textLength = line.text.length;
            for (j in 0...textLength)
            {
                ch = line.text.charAt(j);
                
                glyph = _bitmapFont.glyphs[ch];
                if (glyph != null) 
                {
                    charIndent = Std.int((line.height + line.textHeight) / 2 - Math.ceil(glyph.lineHeight * fontScale));
                    _bitmapFont.draw(_bitmapData, glyph, charX + lineIndent, line.y + charIndent, _color, fontScale);
                    
                    charX += letterSpacing + Math.ceil(glyph.advance * fontScale);
                }
                else if (ch == " ") 
                {
                    charX += letterSpacing + Math.ceil(_bitmapFont.size * fontScale / 2);
                }
                else 
                {
                    charX += letterSpacing;
                }
            }  //text loop  
        }  //line loop  
    }
    
    override private function handleSizeChanged() : Void
    {
        if (!_updatingSize) 
        {
            if (!_widthAutoSize) 
                render();
            else 
                doAlign();
        }
    }
    
    override private function handleGrayedChanged() : Void
    {
        super.handleGrayedChanged();
        updateTextFormat();
    }
    
    private function doAlign() : Void
    {
        if (_verticalAlign == VertAlignType.Top) 
            _yOffset = 0;
        else 
        {
            var dh : Float;
            if (_textHeight == 0) 
                dh = this.height - _textFormat.size;
            else 
                dh = this.height - _textHeight;

            if(dh>_fontAdjustment)
            {
                if (_verticalAlign == VertAlignType.Middle)
                    _yOffset = Std.int((dh - _fontAdjustment)/2);
                else
                    _yOffset = Std.int(dh);
            }
            else
                _yOffset = 0;
        }
        _yOffset -=_fontAdjustment;
        displayObject.y = this.y + _yOffset;
    }
    
    override public function setup_beforeAdd(xml : FastXML) : Void
    {
        super.setup_beforeAdd(xml);
        
        var str : String;
        var arr : Array<Dynamic>;
        
        str = xml.att.font;
        if (str != null) 
            _font = str;
        
        str = xml.att.fontSize;
        if (str != null) 
            _fontSize = Std.parseInt(str);
        
        str = xml.att.color;
        if (str != null) 
            _color = ToolSet.convertFromHtmlColor(str);
        
        str = xml.att.align;
        if (str != null) 
            _align = AlignType.parse(str);
        
        str = xml.att.vAlign;
        if (str != null) 
            _verticalAlign = VertAlignType.parse(str);
        
        str = xml.att.leading;
        if (str != null) 
            _leading = Std.parseInt(str);
        else 
            _leading = 3;
        
        str = xml.att.letterSpacing;
        if (str != null) 
            _letterSpacing = Std.parseInt(str);
        
        _ubbEnabled = xml.att.ubb == "true";
        
        str = xml.att.autoSize;
        if (str != null) 
        {
            _autoSize = AutoSizeType.parse(str);
            _widthAutoSize = _autoSize == AutoSizeType.Both;
            _heightAutoSize = _autoSize == AutoSizeType.Both || _autoSize == AutoSizeType.Height;
            updateAutoSize();
        }
        
        _underline = xml.att.underline == "true";
        _italic = xml.att.italic == "true";
        _bold = xml.att.bold == "true";
        this.singleLine = xml.att.singleLine == "true";
        str = xml.att.strokeColor;
        if (str != null) 
        {
            _strokeColor = ToolSet.convertFromHtmlColor(str);
            str = xml.att.strokeSize;
            if (str != null) 
                _stroke = Std.parseInt(str);
            else 
                _stroke = 1;
        }
        
        str = xml.att.shadowColor;
        if (str != null) 
        {
            if (_stroke <= 0)
                _strokeColor = ToolSet.convertFromHtmlColor(str);
            str = xml.att.shadowOffset;
            if (str != null) 
            {
                arr = str.split(",");
                _shadowOffset = new Point(Std.parseFloat(arr[0]), Std.parseFloat(arr[1]));
            }
        }
        
        updateTextFilters();
    }
    
    override public function setup_afterAdd(xml : FastXML) : Void
    {
        super.setup_afterAdd(xml);
        
        updateTextFormat();
        
        var str : String = xml.att.text;
        if (str != null) 
            this.text = str;
        
        _sizeDirty = false;
    }
}


class LineInfo
{
    public var width : Int = 0;
    public var height : Int = 0;
    public var textHeight : Int = 0;
    public var text : String;
    public var y : Int = 0;
    
    private static var pool : Array<Dynamic> = [];
    
    public static function borrow() : LineInfo
    {
        if (pool.length > 0)
        {
            var ret : LineInfo = pool.pop();
            ret.width = 0;
            ret.height = 0;
            ret.textHeight = 0;
            ret.text = null;
            ret.y = 0;
            return ret;
        }
        else 
        return new LineInfo();
    }
    
    public static function returns(value : LineInfo) : Void
    {
        pool.push(value);
    }
    
    public static function returnList(value : Array<LineInfo>) : Void
    {
        for (li in value)
        {
            pool.push(li);
        }
        value.splice(0, value.length);
    }
    
    public function new()
    {
    }
}

