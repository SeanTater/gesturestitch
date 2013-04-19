var LeapEx = {
  ws: null,
  ctx: null,
  width: null,
  height: null,
  debugEl: null,
  el: null,
  leapMinX: -200,
  leapMaxX: 200,
  leapMinY: 100,
  leapMaxY: 600,
  leapMinZ: -180,
  leapMaxZ: 180,
  started: false,

  init: function(el, debugEl) {

    LeapEx.el = $(el);
    LeapEx.debugEl = $(debugEl);

    // Support both the WebSocket and MozWebSocket objects
    if ((typeof(WebSocket) == 'undefined') &&
        (typeof(MozWebSocket) != 'undefined')) {
      WebSocket = MozWebSocket;
    }

    var w = LeapEx.width = $(window).width();
    var h = LeapEx.height = $(window).height();
    $(el).attr('width', w).css('width', w).attr('height', h).css('height', h);
    $(el).css('position', 'absolute').css('left', '0').css('top', '0');

      var pic = gs.Image.all[2];
      var im = pic.image.offset();
      console.log(im);
      var x1 = im.left;
      var y1 = im.top;
      var locX = im.left;
      var locY = im.top;
      var imW = pic.image.width();
      var imH = pic.image.height();
      var x2 = x1 + pic.image.width();
      var y2 = y1 + pic.image.height();
      var xCenter = (x1 + x2)/2;
      var yCenter = (y1 + y2)/2;
      console.log(gs.Image.all[2].image);
      var imW = gs.Image.all[2].image.width();
      var imH = gs.Image.all[2].image.height();
      var matches = 0;
    LeapEx.ctx = $(el)[0].getContext("2d");
    LeapEx.ws = new WebSocket("ws://localhost:6437/");

    LeapEx.ws.onopen = function(event) {
      LeapEx.debug("WebSocket connection open!");
    };

    LeapEx.ws.onclose = function(event) {
      LeapEx.ws = null;
      LeapEx.debug("WebSocket connection closed");
    };

    LeapEx.ws.onerror = function(event) {
      LeapEx.debug("Received error");
    };
    
    var hovering = false;

    LeapEx.ws.onmessage = function(event) {

      if (LeapEx.started) {
        var obj = JSON.parse(event.data);
        var str = JSON.stringify(obj, undefined, 2);

        LeapEx.debug(str);

        if (typeof(obj.hands) != 'undefined' && obj.hands.length > 0) {
          var targets = [];

          for (var i=0; i<obj.hands.length; i++) {
            var hand = obj.hands[i];
            var x = hand.palmPosition[0];
            var y = hand.palmPosition[1];
            var z = hand.palmPosition[2];

            if (z < 10) { z = 10; }
            targets.push({ 'x': x, 'y': y, 'z': z });
          }

          LX = LeapEx.scale(obj.hands[0].palmPosition[0], LeapEx.leapMinX, LeapEx.leapMaxX, -100, LeapEx.width);
          LY = LeapEx.scale(obj.hands[0].palmPosition[1], LeapEx.leapMinY, LeapEx.leapMaxY, LeapEx.height, -100);
          LeapEx.draw(targets);
          LX = LX - 200;
          LY = LY - 200;

         console.log('Pointing Coords: ' + LX + ', ' + LY);
         gs.Image.all[2].setupCanvas();
         var width = gs.Image.all[2].width;
         var height = gs.Image.all[2].height;

         //If one finger, move left half of image
         if(obj.pointables.length == 1 && obj.hands.length == 1) {
            hovering = true;
            if(LX >= x1 && LX <= (x1+width) && LY >= y1 && LY <= (y2+height)) {
              console.log('INTERSECTION');
           }
            gs.Image.all[2].place(LX, LY);
            if(!gs.Image.all[2].wrapper.hasClass("ui-selected")) {
            gs.Image.all[2].wrapper.addClass("ui-selected");
            gs.Image.all[2].parent.select(gs.Image.all[2]);
           }
          } else if(obj.pointables.length >= 6 && obj.hands.length == 2) {
              hovering = true;
              gs.Image.all[1].place(LX, LY);
              if(!gs.Image.all[1].wrapper.hasClass("ui-selected")) {
              gs.Image.all[1].wrapper.addClass("ui-selected");
              gs.Image.all[1].parent.select(gs.Image.all[2]);
             }
          }
          else if(obj.pointables.length == 0 && obj.hands.length == 2 && matches == 0) {
            gs.Image.all[2].match(gs.Image.all[1]);
            matches = matches + 1;
          }
          else{
            if(gs.Image.all[1].wrapper.hasClass("ui-selected")) {
            //gs.Image.all[1].wrapper.removeClass("ui-selected");
            //gs.Image.all[1].parent.deselect(gs.Image.all[1]);
           }
          }
        
        }
      }
    };

    // $(document.body).click(function() {
    //   LeapEx.toggle();
    // });

    LeapEx.started = true;
    return LeapEx.el;
  },

  findPos: function (obj){
  var curleft = 0;
  var curtop = 0;

  if (obj.offsetParent) {
      do {
          curleft += obj.offsetLeft;
          curtop += obj.offsetTop;
         } while (obj = obj.offsetParent);

      return {X:curleft,Y:curtop};
    }
  },

  draw: function(targets) {
    LeapEx.ctx.clearRect(0, 0, LeapEx.width, LeapEx.height);
    LeapEx.ctx.beginPath();
    for (var i=0; i<targets.length; i++) {
      var target = targets[i];
      LeapEx.ctx.arc(LeapEx.scale(target.x, LeapEx.leapMinX, LeapEx.leapMaxX, -100, LeapEx.width),
                     LeapEx.scale(target.y, LeapEx.leapMinY, LeapEx.leapMaxY, LeapEx.height, -100),
                     10, 0, Math.PI*2, true);
      LeapEx.ctx.closePath();
      LeapEx.ctx.fillStyle = "#008000";
      LeapEx.ctx.fill();
    }
  },

  intersects: function(images) {
    console.log(images);
  },

  scale: function(value, oldMin, oldMax, newMin, newMax) {
    return (((newMax - newMin) * (value - oldMin)) / (oldMax - oldMin)) + newMin;
  },

  toggle: function() {
    if (LeapEx.started) {
      LeapEx.started = false;
    } else {
      LeapEx.started = true;
    }
  },

  debug: function(message) {
    if (LeapEx.debugEl) {
      LeapEx.debugEl.text(message);
    }
  }
};
