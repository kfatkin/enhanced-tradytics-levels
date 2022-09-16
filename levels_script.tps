// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/
// © tradytics
// Modified by Tradytics user @spoll
//@version=5
indicator("Tradytics Levels", overlay=true)

// Inputs {
var string GRP1 = '=====  Level Conversion  ====='
use_other       = input(false,"Use levels from another ticker", group = GRP1)
ratioticker     = input.symbol("NASDAQ:QQQ", "Ticker", group = GRP1)
ratiotimeframe  = input.timeframe("", "Timeframe for price conversion. Uses close of previous candle. May be unstable in pre/post market", group = GRP1)
show_debug      = input(false,"Show debug labels", group = GRP1)

var string GRP1b = '=====  Level Labels  ====='
show_level_labels = input(true, "Label levels", group = GRP1b)
label_detail = input.string("All", "Detail to display", options=["All", "Type", "Type + pos/neg"], group=GRP1b)
label_offset = input.int(30, "Label offset", group = GRP1b)


var string GRP2   = '=====  Gamma levels  ====='
show_G            = input(true, "Show Gamma levels", group = GRP2)
i_codes_input_G   = input.string("", "Input Code - GEX", group = GRP2)
convert_spotgex   = input(false,"Automatically convert GEX to SPOTGEX", group = GRP2)
dash_neg          = input(false, "Use dotted lines for negative GEX levels", group = GRP2)
i_col_sup_G       = input.color(color.green, "Positive Levels", group = GRP2)
i_col_res_G       = input.color(color.red, "Negative Levels", group = GRP2)
i_col_neutral_G   = input.color(color.white, "Neutral Levels", group = GRP2)
opacity_mulp_G    = math.max(input.float(1.5, "Opacity", 0, group = GRP2), 0.5)
width_G           = input.int(2, "Levels Width", 0, group = GRP2)

var string GRP3 = '=====  Delta levels  ====='
show_D            = input(true, "Show Delta levels", group = GRP3)
i_codes_input_D   = input.string("", "Input Code - DEX", group = GRP3)
i_col_sup_D       = input.color(color.green, "Positive Levels", group = GRP3)
i_col_res_D       = input.color(color.red, "Negative Levels", group = GRP3)
i_col_neutral_D   = input.color(color.white, "Neutral Levels", group = GRP3)
opacity_mulp_D    = math.max(input.float(1.5, "Opacity", 0, group = GRP3), 0.5)
width_D           = input.int(2, "Levels Width", 0, group = GRP3)

var string GRP4 = '=====  Vanna levels  ====='
show_V            = input(true, "Show Vanna levels", group = GRP4)
i_codes_input_V   = input.string("", "Input Code - VEX", group = GRP4)
i_col_sup_V       = input.color(color.green, "Positive Levels", group = GRP4)
i_col_res_V       = input.color(color.red, "Negative Levels", group = GRP4)
i_col_neutral_V   = input.color(color.white, "Neutral Levels", group = GRP4)
opacity_mulp_V    = math.max(input.float(1.5, "Opacity", 0, group = GRP4), 0.5)
width_V           = input.int(2, "Levels Width", 0, group = GRP4)

var string GRP5 = '=====  Darkpool levels  ====='
show_Da            = input(true, "Show DarkPool levels", group = GRP5)
i_codes_input_Da   = input.string("", "Input Code - Darkpool", group = GRP5)
i_col_sup_Da       = input.color(color.green, "Positive Levels", group = GRP5)
i_col_res_Da       = input.color(color.red, "Negative Levels", group = GRP5)
i_col_neutral_Da   = input.color(color.white, "Neutral Levels", group = GRP5)
opacity_mulp_Da    = math.max(input.float(1.5, "Opacity", 0, group = GRP5), 0.5)
width_Da           = input.int(2, "Levels Width", 0, group = GRP5)

var string GRP6 = '=====  Support/Resistance levels  ====='
show_S            = input(true, "Show S/R levels", group = GRP6)
i_codes_input_S   = input.string("", "Input Code - S/R", group = GRP6)
i_col_sup_S       = input.color(color.green, "Positive Levels", group = GRP6)
i_col_res_S       = input.color(color.red, "Negative Levels", group = GRP6)
i_col_neutral_S   = input.color(color.white, "Neutral Levels", group = GRP6)
opacity_mulp_S    = math.max(input.float(1.5, "Opacity", 0, group = GRP6), 0.5)
width_S           = input.int(2, "Levels Width", 0, group = GRP6)

// }


tClose = request.security(ticker.modify(ratioticker, session.extended), ratiotimeframe, close)
curClose =  request.security(ticker.modify(syminfo.ticker, session.extended), timeframe = ratiotimeframe, expression = close)


ratio = use_other ? curClose[1] / tClose[1] : 1
if show_debug
    var lbl = label.new(na, na, "", color = color.orange, style = label.style_label_lower_left)
    labelText = "Ratio:" + str.tostring(ratio) + " " + ratioticker + ": " + str.tostring(tClose) + " Chart: " + str.tostring(close)
    // Update the label's position, text and tooltip.
    label.set_xy(lbl, bar_index, close)
    label.set_text(lbl, labelText)

// Functions {
f_trim_array(_array) =>
    for i = 0 to array.size(_array)-1
        if array.get(_array, i) == ""
            array.remove(_array, i)

f_new_line()    => line.new(na, na, na, na, extend=extend.both, style=line.style_solid)
f_new_label()   => label.new(na, na, "", textcolor=color.white, style=label.style_none, size=size.normal)
// }

// Variables {
var string[]    codes_G       = str.split(i_codes_input_G,  " ")
var string[]    codes_D       = str.split(i_codes_input_D,  " ")
var string[]    codes_V       = str.split(i_codes_input_V,  " ")
var string[]    codes_Da      = str.split(i_codes_input_Da, " ")
var string[]    codes_S       = str.split(i_codes_input_S,  " ")
var string[]    labeltext     = array.new_string()

var line[]      lines       = array.new_line()
var label[]     labels      = array.new_label()
var float[]     prices      = array.new_float()

var float       opacity_mulp = na
var int         codesCount  = na
var int         n_G         = 0
var int         n_D         = 0
var int         n_V         = 0
var int         n_Da        = 0
var int         n_S         = 0
var int         width       = na
var string      level       = na
var string      leveltype   = na
var color       lineColor   = na
var color       i_col_sup   = na
var color       i_col_res   = na
var color       i_col_neutral = na

if barstate.isfirst
    // Not sure why this code was included originally by Haider.
    // Leaving commented out for now.
    // Removes empty values - but there's bugs when using this with multiple input boxes
    //f_trim_array(codes_G)
    //f_trim_array(codes_D)
    //f_trim_array(codes_V)
    //f_trim_array(codes_Da)
    //f_trim_array(codes_S)
    n_G  := show_G  ? array.size(codes_G)  : 0
    n_D  := show_D  ? array.size(codes_D)  : 0    
    n_V  := show_V  ? array.size(codes_V)  : 0
    n_Da := show_Da ? array.size(codes_Da) : 0
    n_S  := show_S  ? array.size(codes_S)  : 0
    codesCount := n_G + n_D + n_V + n_Da + n_S

    if codesCount
        // Create "empty" lines and labels
        for i = 0 to codesCount-1
            array.push(lines,  f_new_line())
            array.push(labels, f_new_label())
            array.push(labeltext, "")
            array.push(prices, na)

if barstate.islast and codesCount
    for i = 0 to codesCount-1
        // Get Level
        if i < n_G and show_G
            level       := array.get(codes_G, i)
            leveltype   := "Gamma"
            opacity_mulp := opacity_mulp_G
            width := width_G
            i_col_sup := i_col_sup_G
            i_col_res := i_col_res_G
            i_col_neutral := i_col_neutral_G
        else if i < n_G + n_D and show_D
            level       := array.get(codes_D, i - n_G)
            leveltype   := "Delta"
            opacity_mulp := opacity_mulp_D
            width := width_D
            i_col_sup := i_col_sup_D
            i_col_res := i_col_res_D
            i_col_neutral := i_col_neutral_D
        else if i < n_G + n_D + n_V and show_V
            level       := array.get(codes_V, i - (n_G + n_D))
            leveltype   := "Vanna"
            opacity_mulp := opacity_mulp_V
            width := width_V
            i_col_sup := i_col_sup_V
            i_col_res := i_col_res_V
            i_col_neutral := i_col_neutral_V
        else if i < n_G + n_D + n_V + n_Da and show_Da
            level       := array.get(codes_Da, i - (n_G + n_D + n_V))
            leveltype   := "Darkpool"
            opacity_mulp := opacity_mulp_Da
            width := width_Da
            i_col_sup := i_col_sup_Da
            i_col_res := i_col_res_Da
            i_col_neutral := i_col_neutral_Da
        else
            if show_S
                level       := array.get(codes_S, i - (n_G + n_D + n_V + n_Da))
                leveltype   := "S/R"
                opacity_mulp := opacity_mulp_S
                width := width_S
                i_col_sup := i_col_sup_S
                i_col_res := i_col_res_S
                i_col_neutral := i_col_neutral_S
            
        // Extract price, opacity and positive/negative    
        level_parts = str.split(level, "*")
        level_value = ratio*str.tonumber(array.get(level_parts, 0))
        level_opacity = str.tonumber(array.get(level_parts, 1))
        level_pos_neg = str.tostring(array.get(level_parts, 2))
        // For some reason, support/resistance levels from Trady are labelled strangely 
        // so overwrite their positive/negative with resistance/support depending on where price is
        // in relation to the level
        if leveltype == "S/R"
            level_pos_neg := close < level_value ? "resistance" : "support"
        
        // Create the label text
        txt = leveltype
        if label_detail == "All" or label_detail == "Type + pos/neg"
            txt := txt + " "+level_pos_neg
        if label_detail == "All"
            txt := txt + " "+str.tostring(100-level_opacity)
        
        // Check for other levels at the same price        
        if array.includes(prices, level_value)
            dupindex = array.lastindexof(prices, level_value)
            array.set(labeltext, i, array.get(labeltext, dupindex)+" "+txt)
            array.set(labeltext, dupindex, "")
            array.set(prices, i, level_value)
        else
            array.set(prices, i, level_value)
            array.set(labeltext, i, txt)

        // Move Lines
        lineObject  = array.get(lines, i)
        
        if leveltype == "S/R"
            lineColor := close < level_value ? i_col_res : i_col_sup
        else
            if level_pos_neg == 'positive'
                lineColor := convert_spotgex and leveltype == 'Gamma' ? close > level_value ? i_col_sup : i_col_res : i_col_sup
            if level_pos_neg == 'negative'
                lineColor := convert_spotgex and leveltype == 'Gamma' ? close > level_value ? i_col_res : i_col_sup : i_col_res
            if level_pos_neg == 'neutral'
                lineColor := i_col_neutral
        
            
        color transparentColor = color.new(lineColor, level_opacity / opacity_mulp)
        line.set_xy1(lineObject, bar_index - 1, level_value)
        line.set_xy2(lineObject, bar_index,     level_value)
        line.set_color(lineObject, transparentColor)
        if timeframe.isintraday
            line.set_width(lineObject, width)
        else
            line.set_width(lineObject, width * 2)
        if (level_pos_neg == "negative" and dash_neg and leveltype == "Gamma")
            line.set_style(lineObject, line.style_dotted)
    
    if show_level_labels
        if codesCount
            for i = 0 to codesCount-1
                lbl  = array.get(labels, i)
                label.set_xy(lbl, bar_index + label_offset, array.get(prices, i))
                label.set_text(lbl, array.get(labeltext, i))
