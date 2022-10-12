// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/
// © tradytics
// Modified by Tradytics user @spoll
//@version=5
indicator("Tradytics Levels", overlay=true, max_lines_count = 500, max_boxes_count = 500, max_labels_count = 500)

// Inputs {
var string GRP1 = '=====  Level Conversion  ====='
use_other       = input(false,"Use levels from another ticker", group = GRP1)
ratioticker     = input.symbol("NASDAQ:QQQ", "Ticker", group = GRP1)
ratiotimeframe  = input.timeframe("", "Timeframe for price conversion. Uses close of previous candle. May be unstable in pre/post market", group = GRP1)
show_debug      = input(false,"Show debug labels", group = GRP1)

var string GRP1b = '=====  Level Labels  ====='
show_level_labels = input(true, "Label levels", group = GRP1b)
text_color  = input.color(color.white, "Text color for labels")
label_detail = input.string("All", "Detail to display", options=["All", "Type", "Type + pos/neg"], group=GRP1b)
label_offset = input.int(30, "Label offset", group = GRP1b)
reminder     = input.bool(true, "Show reminder if no levels added", group = GRP1b)

var string GRP1c = '===== Ghost Zones ====='
show_ghost      = input(true, "Show Ghost Zones", group = GRP1c)
invert_ghost      = input(false, "Invert Ghost Zones", group = GRP1c)
ghost_threshold = input.float(0.5, "Percentage difference between levels to plot ghost zone")
chop_region     = input.float(0.5, "Price around level to ignore from ghost zone")
ghost_color     = input.color(color.gray, "Ghost Zone color")
ghost_opacity   = input.float(85, "Opacity (lower is more opaque)")

var string GRP1d = '===== Alerts ====='
use_alerts = input(false, "Be alerted when price crosses a level", group = GRP1d)
alert_on = input.string("All", "Levels to add alerts to", options=["All","Gamma","Delta","Vanna","Darkpool","S/R"], group=GRP1d)
alert_freq = input.string("Once per bar", "Alert frequency", options=["Once per bar", "On bar close", "All"])

var string GRP2   = '=====  Gamma levels  ====='
show_G            = input(true, "Show Gamma levels", group = GRP2)
i_codes_input_G   = input.string("", "Input Code - GEX", group = GRP2)
convert_spotgex   = input(false,"Automatically convert GEX to SPOTGEX", group = GRP2)
i_col_sup_G       = input.color(color.orange, "Positive Levels", group = GRP2)
i_col_res_G       = input.color(color.purple, "Negative Levels", group = GRP2)
i_col_neutral_G   = input.color(color.white, "Neutral Levels", group = GRP2)
opacity_mulp_G    = math.max(input.float(3, "Opacity", 0, group = GRP2), 0.5)
width_G           = input.int(2, "Levels Width", 0, group = GRP2)
dash_G        = input(false, "Use dashed lines for Gamma levels")

var string GRP3 = '=====  Delta levels  ====='
show_D            = input(true, "Show Delta levels", group = GRP3)
i_codes_input_D   = input.string("", "Input Code - DEX", group = GRP3)
i_col_sup_D       = input.color(color.green, "Positive Levels", group = GRP3)
i_col_res_D       = input.color(color.red, "Negative Levels", group = GRP3)
i_col_neutral_D   = input.color(color.white, "Neutral Levels", group = GRP3)
opacity_mulp_D    = math.max(input.float(1.5, "Opacity", 0, group = GRP3), 0.5)
width_D           = input.int(2, "Levels Width", 0, group = GRP3)
dash_D            = input(false, "Use dashed lines for Delta levels")

var string GRP4 = '=====  Vanna levels  ====='
show_V            = input(true, "Show Vanna levels", group = GRP4)
i_codes_input_V   = input.string("", "Input Code - VEX", group = GRP4)
i_col_sup_V       = input.color(color.green, "Positive Levels", group = GRP4)
i_col_res_V       = input.color(color.red, "Negative Levels", group = GRP4)
i_col_neutral_V   = input.color(color.white, "Neutral Levels", group = GRP4)
opacity_mulp_V    = math.max(input.float(1.5, "Opacity", 0, group = GRP4), 0.5)
width_V           = input.int(2, "Levels Width", 0, group = GRP4)
dash_V            = input(false, "Use dashed lines for Vanna levels")

var string GRP5 = '=====  Darkpool levels  ====='
show_Da            = input(true, "Show DarkPool levels", group = GRP5)
i_codes_input_Da   = input.string("", "Input Code - Darkpool", group = GRP5)
i_col_sup_Da       = input.color(color.green, "Positive Levels", group = GRP5)
i_col_res_Da       = input.color(color.red, "Negative Levels", group = GRP5)
i_col_neutral_Da   = input.color(color.white, "Neutral Levels", group = GRP5)
opacity_mulp_Da    = math.max(input.float(1.5, "Opacity", 0, group = GRP5), 0.5)
width_Da           = input.int(2, "Levels Width", 0, group = GRP5)
dash_Da            = input(false, "Use dashed lines for Darkpool levels")

var string GRP6 = '=====  Support/Resistance levels  ====='
show_S            = input(true, "Show S/R levels", group = GRP6)
i_codes_input_S   = input.string("", "Input Code - S/R", group = GRP6)
i_col_sup_S       = input.color(color.green, "Positive Levels", group = GRP6)
i_col_res_S       = input.color(color.red, "Negative Levels", group = GRP6)
i_col_neutral_S   = input.color(color.white, "Neutral Levels", group = GRP6)
opacity_mulp_S    = math.max(input.float(1.5, "Opacity", 0, group = GRP6), 0.5)
width_S           = input.int(2, "Levels Width", 0, group = GRP6)
dash_S            = input(false, "Use dashed lines for support/resistance levels")
// }

var string GRP7 = '===== VWAPs ====='

// Rolling VWAP script originally found here: https://in.tradingview.com/script/ZU2UUu9T-Rolling-VWAP/

bool plot_vwap        = input.bool(true, "Plot VWAP", group = GRP7)
float vwap_source      = input(hlc3, "Source for VWAP", group = GRP7)
color vwap_colour      = input.color(color.purple, "Colour for VWAP", group = GRP7)
bool plot_rolling_vwap = input.bool(true, "Plot Rolling VWAP", group = GRP7)
float srcInput        = input.source(hlc3, "Source for Rolling VWAP", tooltip = "The source used to calculate the Rolling VWAP. The default is the average of the high, low and close prices.", group = GRP7)
color rolling_vwap_colour   = input.color(color.orange, "Colour for Rolling VWAP", group = GRP7)
var string TT_WINDOW = "By default, the time period used to calculate the RVWAP automatically adjusts with the chart's timeframe.
  Check this to use a fixed-size time period instead, which you define with the following three values."
bool fixedTfInput     = input.bool(false, "Use a fixed time period for Rolling VWAP", group = GRP7, tooltip = TT_WINDOW)

int MS_IN_MIN   = 60 * 1000
int MS_IN_HOUR  = MS_IN_MIN  * 60
int MS_IN_DAY   = MS_IN_HOUR * 24
int  daysInput        = input.int(1, "Days", minval = 0, maxval = 90, group = GRP7) * MS_IN_DAY
int  hoursInput       = input.int(0, "Hours", minval = 0, maxval = 23, group = GRP7) * MS_IN_HOUR
int  minsInput        = input.int(0, "Minutes", minval = 0, maxval = 59, group = GRP7) * MS_IN_MIN
bool tableInput       = input.bool(true, "Show time period", group = GRP7, tooltip = "Displays the time period of the rolling window.")
string textSizeInput  = input.string("large", "Text size", group = GRP7, options = ["tiny", "small", "normal", "large", "huge", "auto"])
string tableYposInput = input.string("bottom", "Position     ", inline = "21", group = GRP7, options = ["top", "middle", "bottom"])
string tableXposInput = input.string("left", "", inline = "21", group = GRP7, options = ["left", "center", "right"])
var string TT_MINBARS = "The minimum number of last values to keep in the moving window, even if these values are outside the time period.
  This avoids situations where a large time gap between two bars would cause the time window to be empty."
int  minBarsInput     = input.int(10, "Bars", group = GRP7, tooltip = TT_MINBARS)

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

f_remove_duplicates(_string) =>
    unique_entries = array.new_string()
    entries = str.split(_string, " ")
    for e in entries
        if e != "" and not array.includes(unique_entries, e)
            array.push(unique_entries, e)
    unique_entries
        
f_new_line()    => line.new(na, na, na, na, extend=extend.both, style=line.style_solid)
f_new_label()   => label.new(na, na, "", textcolor=color.white, style=label.style_none, size=size.normal)
f_new_GZ()      => box.new(na, na, na, na, bgcolor=color.new(ghost_color, ghost_opacity), border_width=0)
// }

// Variables {
var string[]    codes_G       = f_remove_duplicates(i_codes_input_G)//str.split(i_codes_input_G,  " ")
var string[]    codes_D       = f_remove_duplicates(i_codes_input_D)//str.split(i_codes_input_D,  " ")
var string[]    codes_V       = f_remove_duplicates(i_codes_input_V)//str.split(i_codes_input_V,  " ")
var string[]    codes_Da      = f_remove_duplicates(i_codes_input_Da)//str.split(i_codes_input_Da, " ")
var string[]    codes_S       = f_remove_duplicates(i_codes_input_S)//str.split(i_codes_input_S,  " ")
var string[]    labeltext     = array.new_string()
var box[]       ghostZones    = array.new_box()

var line[]      lines       = array.new_line()
var label[]     labels      = array.new_label()
var float[]     prices      = array.new_float()
var float[]     unique_prices = array.new_float()

var float       opacity_mulp = na
var int         codesCount  = 0
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
    n_G  := show_G  ? array.size(codes_G)  : 0
    n_D  := show_D  ? array.size(codes_D)  : 0
    n_V  := show_V  ? array.size(codes_V)  : 0
    n_Da := show_Da ? array.size(codes_Da) : 0
    n_S  := show_S  ? array.size(codes_S)  : 0
    codesCount := n_G + n_D + n_V + n_Da + n_S
    
    if codesCount > 0
        // Create "empty" lines and labels
        for i = 0 to codesCount-1
            array.push(lines,  f_new_line())
            array.push(labels, f_new_label())
            array.push(labeltext, "")
            array.push(prices, na)
            array.push(ghostZones, f_new_GZ())

if codesCount == 0 and reminder
    var error_lbl = label.new(na, na, "", color = color.orange, style = label.style_label_lower_left)
    error_labelText = "Please copy some levels from the Tradytics website to use this indicator"
    // Update the label's position, text and tooltip.
    label.set_xy(error_lbl, bar_index, close)
    label.set_text(error_lbl, error_labelText)

if barstate.islast and codesCount > 0
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
        level_value = str.tonumber(array.get(level_parts, 0))
        level_opacity = str.tonumber(array.get(level_parts, 1))
        level_pos_neg = str.tostring(array.get(level_parts, 2))
        // For some reason, support/resistance levels from Trady are labelled strangely
        // so overwrite their positive/negative with resistance/support depending on where price is
        // in relation to the level
        if leveltype == "S/R"
            level_pos_neg := close < ratio*level_value ? "resistance" : "support"

        // Create the label text
        txt = leveltype
        if label_detail == "All" or label_detail == "Type + pos/neg"
            txt := txt + " "+level_pos_neg
        if label_detail == "All"
            txt := txt + " "+str.tostring(101-level_opacity)

        // Check for other levels at the same price
        if array.includes(prices, level_value)
            dupindex = array.lastindexof(prices, level_value)
            array.set(labeltext, i, array.get(labeltext, dupindex)+" "+txt)
            array.set(labeltext, dupindex, "")
            array.set(prices, i, level_value)
        else
            array.set(prices, i, level_value)
            array.set(labeltext, i, txt)
            // Store the unique non-S/R levels to show ghost zones if desired
            if (leveltype != "S/R" and leveltype != "Darkpool") and not array.includes(unique_prices, level_value)
                array.push(unique_prices, level_value)

        // Move Lines
        lineObject  = array.get(lines, i)

        if leveltype == "S/R"
            lineColor := close < ratio*level_value ? i_col_res : i_col_sup
        else
            if level_pos_neg == 'positive'
                lineColor := convert_spotgex and leveltype == 'Gamma' ? close > ratio*level_value ? i_col_sup : i_col_res : i_col_sup
            if level_pos_neg == 'negative'
                lineColor := convert_spotgex and leveltype == 'Gamma' ? close > ratio*level_value ? i_col_res : i_col_sup : i_col_res
            if level_pos_neg == 'neutral'
                lineColor := i_col_neutral


        color transparentColor = color.new(lineColor, level_opacity / opacity_mulp)
        line.set_xy1(lineObject, bar_index - 1, ratio*level_value)
        line.set_xy2(lineObject, bar_index,     ratio*level_value)
        line.set_color(lineObject, transparentColor)
        if timeframe.isintraday
            line.set_width(lineObject, width)
        else
            line.set_width(lineObject, width * 2)
        
        if (dash_G and leveltype == "Gamma")
            line.set_style(lineObject, line.style_dotted)
        if (dash_D and leveltype == "Delta")
            line.set_style(lineObject, line.style_dotted)
        if (dash_V and leveltype == "Vanna")
            line.set_style(lineObject, line.style_dotted)
        if (dash_Da and leveltype == "Darkpool")
            line.set_style(lineObject, line.style_dotted)
        if (dash_S and leveltype == "S/R")
            line.set_style(lineObject, line.style_dotted)
            

//if barstate.islast
if show_level_labels and codesCount > 0
    if array.size(labels) > 0
        for i = 0 to array.size(labels)-1
            lbl  = array.get(labels, i)
            txt = array.get(labeltext, i)
            if txt != ""
                label.set_xy(lbl, bar_index + label_offset, ratio*array.get(prices, i))
                label.set_text(lbl, txt)
                label.set_textcolor(lbl, text_color)

if barstate.islast
    if show_ghost and codesCount > 0
        array.sort(unique_prices, order.descending)
        if invert_ghost
            for i = 0 to array.size(unique_prices)-1
                upper = ratio*array.get(unique_prices, i) + (ratio*chop_region)
                lower = ratio*array.get(unique_prices, i) - (ratio*chop_region)
                ghostObject = array.get(ghostZones, i)
                box.set_left(ghostObject,bar_index)
                box.set_right(ghostObject,bar_index+1)
                box.set_top(ghostObject,upper)
                box.set_bottom(ghostObject,lower)
                box.set_extend(ghostObject,extend.both)
        else
            for i = 1 to array.size(unique_prices)-1
                upper = ratio*array.get(unique_prices, i-1)
                lower = ratio*array.get(unique_prices, i)
                if upper/lower >= 1 + (ghost_threshold / 100)
                    ghostObject = array.get(ghostZones, i)
                    box.set_left(ghostObject,bar_index)
                    box.set_right(ghostObject,bar_index+1)
                    box.set_top(ghostObject,upper-(ratio*chop_region))
                    box.set_bottom(ghostObject,lower+(ratio*chop_region))
                    box.set_extend(ghostObject,extend.both)

// Check for crosses.
if use_alerts and codesCount > 0
    var alerttxt = ""
    var cross = false
    for i = 0 to array.size(prices)-1
        float linePrice = array.get(prices,i)
        bool newCrossUp = close[1] < ratio*linePrice and close > ratio*linePrice
        bool newCrossDn = close[1] > ratio*linePrice and close < ratio*linePrice
        if newCrossUp or newCrossDn
            txt = array.get(labeltext, i)
            if txt != ""
                if alert_on != "All"
                    levelinfo = str.split(txt, " ")
                    if array.includes(levelinfo, alert_on)
                        cross := true
                        alerttxt := alerttxt + "Cross at "+str.tostring(ratio*linePrice)+" - "+txt+"\n"    
                else
                    cross := true
                    alerttxt := alerttxt + "Cross at "+str.tostring(ratio*linePrice)+" - "+txt+"\n"
    if cross
        if alert_freq == "Once per bar"
            alert(alerttxt, alert.freq_once_per_bar)
        if alert_freq == "On bar close"
            alert(alerttxt, alert.freq_once_per_bar_close)
        if alert_freq == "All"
            alert(alerttxt, alert.freq_all)
    
    
// Debug stuff below here for labels and ghost zones
//var lbl = label.new(na, na, "", color = color.orange, style = label.style_label_lower_left)
//labelText = "Unique:" + str.tostring(array.size(unique_prices)) + "label text:" + str.tostring(array.size(labeltext)) + "labels:" + str.tostring(array.size(labels))
//var string txt = ""
//if array.size(unique_prices) > 0
//    for i = 0 to array.size(unique_prices)-1
//        txt := txt + " \n"+str.tostring(array.get(unique_prices, i))
//// Update the label's position, text and tooltip.
//label.set_xy(lbl, bar_index, close)
//label.set_text(lbl, labelText)

// Rolling VWAP stuff
// Rolling VWAP script originally found here: https://in.tradingview.com/script/ZU2UUu9T-Rolling-VWAP/
import PineCoders/ConditionalAverages/1 as pc

// ———————————————————— Functions {

timeStep() =>
    // @function    Determines a time period from the chart's timeframe.
    // @returns     (int) A value of time in milliseconds that is appropriate for the current chart timeframe. To be used in the RVWAP calculation.
    int tfInMs = timeframe.in_seconds() * 1000
    float step =
      switch
        tfInMs <= MS_IN_MIN        => MS_IN_HOUR
        tfInMs <= MS_IN_MIN * 5    => MS_IN_HOUR * 4
        tfInMs <= MS_IN_HOUR       => MS_IN_DAY * 1
        tfInMs <= MS_IN_HOUR * 4   => MS_IN_DAY * 3
        tfInMs <= MS_IN_HOUR * 12  => MS_IN_DAY * 7
        tfInMs <= MS_IN_DAY        => MS_IN_DAY * 30.4375
        tfInMs <= MS_IN_DAY * 7    => MS_IN_DAY * 90
        => MS_IN_DAY * 365
    int result = int(step)


tfString(int timeInMs) =>
    // @function    Produces a string corresponding to the input time in days, hours, and minutes.
    // @param       (series int) A time value in milliseconds to be converted to a string variable. 
    // @returns     (string) A string variable reflecting the amount of time from the input time.
    int s  = timeInMs / 1000
    int m  = s / 60
    int h  = m / 60
    int tm = math.floor(m % 60)
    int th = math.floor(h % 24)
    int d  = math.floor(h / 24)
    string result = 
      switch
        d == 30 and th == 10 and tm == 30 => "1M"
        d == 7  and th == 0  and tm == 0  => "1W"
        =>
            string dStr = d  ? str.tostring(d)  + "D "  : ""
            string hStr = th ? str.tostring(th) + "H "  : ""
            string mStr = tm ? str.tostring(tm) + "min" : ""
            dStr + hStr + mStr
// }



// ———————————————————— Calculations and Plots {

// Stop the indicator on charts with no volume.
if barstate.islast and ta.cum(nz(volume)) == 0
    runtime.error("No volume is provided by the data vendor.")

// RVWAP + stdev bands
var int timeInMs   = fixedTfInput ? minsInput + hoursInput + daysInput : timeStep()

float sumSrcVol    = pc.totalForTimeWhen(srcInput * volume, timeInMs, true, minBarsInput)
float sumVol       = pc.totalForTimeWhen(volume, timeInMs, true, minBarsInput)
float sumSrcSrcVol = pc.totalForTimeWhen(volume * math.pow(srcInput, 2), timeInMs, true, minBarsInput)

float rollingVWAP  = sumSrcVol / sumVol

plotVWAP = plot(plot_vwap ? ta.vwap(vwap_source) : na, title='VWAP', color=vwap_colour, style=plot.style_line)
plotRollingVWAP = plot(plot_rolling_vwap ? rollingVWAP : na, title="Rolling VWAP", color=rolling_vwap_colour, style=plot.style_line)

// Display of time period.
var table tfDisplay = table.new(tableYposInput + "_" + tableXposInput, 1, 1)
if tableInput
    table.cell(tfDisplay, 0, 0, tfString(timeInMs), bgcolor = na, text_color = color.gray, text_size = textSizeInput)
// }
