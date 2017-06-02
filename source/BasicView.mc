using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Timer as Timer;

enum {
  SCREEN_SHAPE_CIRC = 0x000001,
  SCREEN_SHAPE_SEMICIRC = 0x000002,
  SCREEN_SHAPE_RECT = 0x000003
}

class BasicView extends Ui.WatchFace {

    // globals
    var debug = false;
    var timer1;
    var timer_timeout = 80;
    var timer_steps = timer_timeout;

    // sensors / status
    var battery = 0;
    var bluetooth = true;

    // time
    var hour = null;
    var minute = null;
    var day = null;
    var day_of_week = null;
    var month_str = null;
    var month = null;

    // layout
    var vert_layout = false;
    var canvas_h = 0;
    var canvas_w = 0;
    var canvas_shape = 0;
    var canvas_rect = false;
    var canvas_circ = false;
    var canvas_semicirc = false;
    var canvas_tall = false;
    var canvas_r240 = false;
    var offset = 0;

    // settings
    var set_leading_zero = false;
    var colour_blend = true; // <-- change to toggle alpha on or off

    // fonts
    var f_brushes = null;
    var f_digit_bold = null;
    var f_digit_thin = null;


    // brushes array
    // 4 bytes are stored as a packed signed integer for efficiency.
    // --------------
    const brushes = [
      [16777216,33560576,50343936,67127296,83910656,100663320,117446680,134230040,151013400,167796760,184580120,201326640,218110000,234905648],[251664384,268447744,285218840,302002200,318785560,335550512,352333872,369117232,385888328,402671688],[419436544,436219904,453003264,469768216,486551576,503334936,520118296,536870960,553654320,570437680,587221040,603985992,620769352,637540448],[654317568,671100928,687865880,704649240,721432600,738215960,754974768,771758128,788541488,805324848,822089800,838873160,855656520],[872421376,889204736,905988096,922746904,939530264,956313624,973096984,989855792,1006639152,1023422512,1040187464,1056970824,1073754184,1090519136,1107302496],[1124073472,1140856832,1157640192,1174405144,1191188504,1207971864,1224736816,1241520176],[1258291200,1275074560,1291857920,1308622872,1325406232,1342189592,1358954544,1375737904,1392521264,1409304624,1426063432,1442846792,1459630152,1476413512,1493178464,1509967968],[1526732800,1543516160,1560281112,1577064472,1593847832,1610631192,1627390000,1644173360,1660956720,1677740080,1694498888,1711282248,1728065608,1744848968,1761613920,1778397280,1795180640,1811951736],[1828716544,1845499904,1862283264,1879066624,1895825432,1912608792,1929392152,1946163248],[1962934272,1979717632,1996500992,2013284352,2030043160,2046826520,2063609880,2080393240,2097158192,2113941552],[2130712576,-2147471360,-2130688000,-2113929192,-2097145832,-2080362472,-2063579112,-2046795752,-2030036944,-2013253584,-1996470224,-1979686864,-1962928056,-1946144696,-1912584120,-1895819168,-1879035808],[-1862264832,-1845481472,-1828698112,-1811914752,-1795162088,-1778378728,-1761595368,1728071704,-1744805864,-1728022504,-1711275984,-1694492624,-1677709264,-1660925904,-1644142544,-1627383736,-1610600376,-1593817016,-1577033656]
    ];
    const brushes_length = brushes.size();


    // colour arrays
    // --------------
    const pink_colours = [
      0xFF0000, 0x5500AA, 0xAA00AA, 0xAA00FF, 0xFF0055, 0xFF00FF, 0xFFAAFF
    ];

    const fire_colours = [
      0x550000, 0xAA0000, 0xFF0000, 0xFF0055
    ];

    const red_blue_colours = [
      0xFF0000, 0x0000FF
    ];

    const blue_colours = [
      0x000055,0x0000AA,0x0000FF,0x0055FF,0x00FFFF,0x55FFFF
    ];

    const green_colours = [
      0x005500, 0x00AA00, 0x00FF00, 0x55FF00, 0xAAFF00, 0xFFFF00
    ];

    const multi_colours = [
      0x000055,0x0000AA,0x0000FF,0x0055FF,0x00FFFF,0x55FFFF,
      0x550000, 0xAA0000, 0xFF0000, 0xFF0055,
      0xFF0000, 0x5500AA, 0xAA00AA, 0xAA00FF, 0xFF0055, 0xFF00FF, 0xFFAAFF,
      0x005500, 0x00AA00, 0x00FF00, 0x55FF00, 0xAAFF00, 0xFFFF00
    ];

    const orig_colours = [
      0x000055,0x0000AA,0x0000FF,0x0055FF,0x00FFFF,0x55FFFF
    ];

    const colours = [
      [0xFF0000, 0x5500AA, 0xAA00AA, 0xAA00FF, 0xFF0055, 0xFF00FF, 0xFFAAFF],
      [0x550000, 0xAA0000, 0xFF0000, 0xFF0055],
      [0xFF0000, 0x0000FF],
      [0x000055,0x0000AA,0x0000FF,0x0055FF,0x00FFFF,0x55FFFF],
      [0x005500, 0x00AA00, 0x00FF00, 0x55FF00, 0xAAFF00, 0xFFFF00]
    ];

    const colours_length = colours.size();



    // pass a tilemap array, and the corresponding font, and draw the tile
    // --------------------------
    function drawTiles(current_hand,font,dc,xoff,yoff) {
      var offset = 0;

      for(var i = 0; i < current_hand.size(); i++)
      {
        var packed_value = current_hand[i];

        var ypos = packed_value & 255;
        packed_value >>= 8;
        var xpos = packed_value & 255;
        packed_value >>= 8;
        var char_a = packed_value & 255;
        packed_value >>= 8;
        var char_b = packed_value & 255;

        var char = char_a + char_b;
        dc.drawText(xoff+offset+(xpos.toNumber()),yoff+offset+(ypos.toNumber()),font,(char.toNumber()+32).toChar(),Gfx.TEXT_JUSTIFY_LEFT);
      }

    }

    function initialize() {
     Ui.WatchFace.initialize();
    }


    function onLayout(dc) {

      // w,h of canvas
      canvas_w = dc.getWidth();
      canvas_h = dc.getHeight();

      // check the orientation
      if ( canvas_h > (canvas_w*1.2) ) {
        vert_layout = true;
      } else {
        vert_layout = false;
      }

      // let's grab the canvas shape
      var deviceSettings = Sys.getDeviceSettings();
      canvas_shape = deviceSettings.screenShape;

      if (debug) {
        Sys.println(Lang.format("canvas_shape: $1$", [canvas_shape]));
      }

      // find out the type of screen on the device
      canvas_tall = (vert_layout && canvas_shape == SCREEN_SHAPE_RECT) ? true : false;
      canvas_rect = (canvas_shape == SCREEN_SHAPE_RECT && !vert_layout) ? true : false;
      canvas_circ = (canvas_shape == SCREEN_SHAPE_CIRC) ? true : false;
      canvas_semicirc = (canvas_shape == SCREEN_SHAPE_SEMICIRC) ? true : false;
      canvas_r240 =  (canvas_w == 240 && canvas_w == 240) ? true : false;

      // set offsets based on screen type
      // positioning for different screen layouts
      if (canvas_tall) {
      }
      if (canvas_rect) {
      }
      if (canvas_circ) {
        if (canvas_r240) {
          offset = 10;
        } else {
          offset = 0;
        }
      }
      if (canvas_semicirc) {
      }

      // here's where we load the brushes resources,
      // either with alpha to blend colours, or solid without alpha.
      if (colour_blend) {
        f_brushes = Ui.loadResource(Rez.Fonts.brushes_alpha);
      } else {
        f_brushes = Ui.loadResource(Rez.Fonts.brushes_solid);
      }

      f_digit_bold = Ui.loadResource(Rez.Fonts.digit_bold);
      f_digit_thin = Ui.loadResource(Rez.Fonts.digit_thin);

    }


    function onShow() {
    }


    //! Update the view
    function onUpdate(dc) {


      // grab time objects
      var clockTime = Sys.getClockTime();
      var date = Time.Gregorian.info(Time.now(),0);

      // define time, day, month variables
      hour = clockTime.hour;
      minute = clockTime.min;
      day = date.day;
      month = date.month;
      day_of_week = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
      month_str = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).month;

      // grab battery
      var stats = Sys.getSystemStats();
      var batteryRaw = stats.battery;
      battery = batteryRaw > batteryRaw.toNumber() ? (batteryRaw + 1).toNumber() : batteryRaw.toNumber();

      // do we have bluetooth?
      var deviceSettings = Sys.getDeviceSettings();
      bluetooth = deviceSettings.phoneConnected;

      var this_colours = colours[minute%colours_length];
      var this_colours_length = this_colours.size();

      // 12-hour support
      if (hour > 12 || hour == 0) {
          if (!deviceSettings.is24Hour)
              {
              if (hour == 0)
                  {
                  hour = 12;
                  }
              else
                  {
                  hour = hour - 12;
                  }
              }
      }

      // add padding to units if required
      if( minute < 10 ) {
          minute = "0" + minute;
      }

      if( hour < 10 && set_leading_zero) {
          hour = "0" + hour;
      }

      if( day < 10 ) {
          day = "0" + day;
      }

      if( month < 10 ) {
          month = "0" + month;
      }


      // clear the screen
      dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
      dc.clear();

      // w,h of canvas
      var dw = dc.getWidth();
      var dh = dc.getHeight();
      var dw_h = dw/2;
      var dh_h = dh/2;
      var x_pos = 0;
      var y_pos = 0;


      // draw brushes
      // --------------

      // ok, here's where the rubber hits the road...
      // iterate through 50 random brushes, at random positions, and render then to the screen
      for (var b=0; b<50;b++) {
        x_pos = (Math.rand()%(dw_h)+offset);
        y_pos = (Math.rand()%(dh_h)+offset);
        dc.setColor(this_colours[Math.rand()%this_colours_length], Gfx.COLOR_TRANSPARENT);
        // 'drawTiles' method renders to the screen using my custom tilemap routine
        drawTiles(brushes[Math.rand()%brushes_length],f_brushes,dc,x_pos,y_pos);
      }


      // draw time
      // --------------

      // lets position the time in the center of the screen
      var f_minute = dc.getTextWidthInPixels(minute.toString(), f_digit_thin);
      var f_hour = dc.getTextWidthInPixels(hour.toString(), f_digit_bold);
      var padding = 4;
      var f_width = f_hour + f_minute;
      var f_start = (dw - f_width)/2;

      var y_font = (dh/2)-(dc.getFontHeight(f_digit_bold)/2);
      var x_min = f_start+f_hour+padding;

      // draw the 'outline' of the time using pixel offsets
      // this is a 'cheap' way of anti-aliasing an outline...
      // ...not great, but it works!
      dc.setColor(0xFFFFFF, Gfx.COLOR_TRANSPARENT);
      dc.drawText(1+f_start,1+y_font,f_digit_bold,hour.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(1+x_min,  1+y_font,f_digit_thin,minute.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(-1+f_start,-1+y_font,f_digit_bold,hour.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(-1+x_min,  -1+y_font,f_digit_thin,minute.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText( 1+f_start,-1+y_font,f_digit_bold,hour.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText( 1+x_min,  -1+y_font,f_digit_thin,minute.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(-1+f_start, 1+y_font,f_digit_bold,hour.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(-1+x_min,   1+y_font,f_digit_thin,minute.toString(),Gfx.TEXT_JUSTIFY_LEFT);

      // draw the actual time
      dc.setColor(0x000000, Gfx.COLOR_TRANSPARENT);
      dc.drawText(f_start,y_font,f_digit_bold,hour.toString(),Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(x_min,y_font,f_digit_thin,minute.toString(),Gfx.TEXT_JUSTIFY_LEFT);


    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    // this is our animation loop callback
    function callback1() {

      // redraw the screen
      Ui.requestUpdate();

      // timer not greater than 500ms? then let's start the timer again
      if (timer_steps < 500) {
        timer1 = new Timer.Timer();
        timer1.start(method(:callback1), timer_steps, false );
      } else {
        // timer exists? stop it
        if (timer1) {
          timer1.stop();
        }
      }


    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {

      // let's start our animation loop
      /*
      timer1 = new Timer.Timer();
      timer1.start(method(:callback1), timer_steps, false );
      */
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {

      // bye bye timer
      if (timer1) {
        timer1.stop();
      }

      timer_steps = timer_timeout;


    }

}
