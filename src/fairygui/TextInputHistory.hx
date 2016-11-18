package fairygui;


import openfl.text.TextField;

class TextInputHistory
{
    public static var inst(get, never) : TextInputHistory;

    private static var _inst : TextInputHistory;
    private static function get_inst() : TextInputHistory
    {
        if (_inst == null) 
            _inst = new TextInputHistory();
        return _inst;
    }
    
    private var _undoBuffer : Array<String>;
    private var _redoBuffer : Array<String>;
    private var _currentText : String;
    private var _textField : TextField;
    private var _lock : Bool;
    
    public var maxHistoryLength : Int = 5;
    
    public function new()
    {
        _undoBuffer = new Array<String>();
        _redoBuffer = new Array<String>();
    }
    
    public function startRecord(textField : TextField) : Void
    {
        _undoBuffer.splice(0, -1);
        _redoBuffer.splice(0, -1);
        _textField = textField;
        _lock = false;
        _currentText = textField.text;
    }
    
    public function markChanged(textField : TextField) : Void
    {
        if (_textField != textField) 
            return;
        
        if (_lock) 
            return;
        
        var newText : String = _textField.text;
        if (_currentText == newText) 
            return;
        
        _undoBuffer.push(_currentText);
        if (_undoBuffer.length > maxHistoryLength) 
            _undoBuffer.splice(0, 1);
        
        _currentText = newText;
    }
    
    public function stopRecord(textField : TextField) : Void
    {
        if (_textField != textField) 
            return;

        _undoBuffer.splice(0, -1);
        _redoBuffer.splice(0, -1);
        _textField = null;
        _currentText = null;
    }
    
    public function undo(textField : TextField) : Void
    {
        if (_textField != textField) 
            return;
        
        if (_undoBuffer.length == 0) 
            return;
        
        var text : String = _undoBuffer.pop();
        _redoBuffer.push(_currentText);
        _lock = true;
        _textField.text = text;
        _currentText = text;
        _lock = false;
    }
    
    public function redo(textField : TextField) : Void
    {
        if (_textField != textField) 
            return;
        
        if (_redoBuffer.length == 0) 
            return;
        
        var text : String = _redoBuffer.pop();
        _undoBuffer.push(_currentText);
        _lock = true;
        _textField.text = text;
        var dlen : Int = text.length - _currentText.length;
        if (dlen > 0) 
            _textField.setSelection(_textField.caretIndex + dlen, _textField.caretIndex + dlen);
        
        _currentText = text;
        _lock = false;
    }
}
