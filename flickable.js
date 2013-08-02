(function() {
  var root, _ref;

  root = (_ref = typeof window !== "undefined" && window !== null ? window : global) != null ? _ref : this;

  root.namespace = function(namespace, fn) {
    var context, klass, token, _i, _len, _ref1, _ref2;

    klass = fn();
    context = root;
    _ref1 = namespace.split(".");
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      token = _ref1[_i];
      if ((_ref2 = context[token]) == null) {
        context[token] = {};
      }
      context = context[token];
    }
    return context[klass.name] = klass;
  };

  namespace("Flickable", function() {
    var Helper;

    return Helper = (function() {
      function Helper() {
        this.div = document.createElement("div");
        this.prefixes = ["webkit", "moz", "o", "ms"];
        this.saveProp = {};
      }

      Helper.prototype.getPage = function(event, page) {
        if (event.changedTouches) {
          return event.changedTouches[0][page];
        } else {
          return event[page];
        }
      };

      Helper.prototype.hasProp = function(props) {
        var prop, _i, _len;

        if (props instanceof Array) {
          for (_i = 0, _len = props.length; _i < _len; _i++) {
            prop = props[_i];
            if (this.div.style[prop] !== void 0) {
              return true;
            }
          }
          return false;
        } else if (typeof props === "string") {
          if (this.div.style[prop] !== void 0) {
            return true;
          } else {
            return false;
          }
        } else {
          throw new TypeError("Must be a Array or String");
        }
      };

      Helper.prototype.setStyle = function(element, styles) {
        var hasSaveProp, prop, style, _results, _setAttr,
          _this = this;

        style = element.style;
        hasSaveProp = this.saveProp[prop];
        _setAttr = function(style, prop, val) {
          var prefix, _i, _len, _prop, _ref1;

          if (hasSaveProp) {
            style[hasSaveProp] = val;
          } else if (style[prop] !== void 0) {
            _this.saveProp[prop] = prop;
            style[prop] = val;
          } else {
            _ref1 = _this.prefixes;
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              prefix = _ref1[_i];
              _prop = _this.ucFirst(prefix) + _this.ucFirst(prop);
              if (style[_prop] !== void 0) {
                _this.saveProp[prop] = _prop;
                style[_prop] = val;
                return true;
              }
            }
            return false;
          }
        };
        _results = [];
        for (prop in styles) {
          _results.push(_setAttr(style, prop, styles[prop]));
        }
        return _results;
      };

      Helper.prototype.getCSSVal = function(prop) {
        var prefix, ret, _i, _len, _prop, _ref1;

        if (typeof prop !== "string") {
          throw new TypeError("Must be a String");
        }
        if (this.div.style[prop] !== void 0) {
          return prop;
        } else {
          _ref1 = this.prefixes;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            prefix = _ref1[_i];
            _prop = this.ucFirst(prefix) + this.ucFirst(prop);
            if (this.div.style[_prop] !== void 0) {
              ret = "-" + prefix + "-" + prop;
            }
          }
          return ret;
        }
      };

      Helper.prototype.ucFirst = function(str) {
        if (typeof str !== "string") {
          throw new TypeError("Must be a String");
        }
        return str.charAt(0).toUpperCase() + str.substr(1);
      };

      Helper.prototype.triggerEvent = function(element, type, bubbles, cancelable, data) {
        var d, event;

        if (typeof element !== "object") {
          throw new Error("Must be a Element");
        }
        event = document.createEvent("Event");
        event.initEvent(type, bubbles, cancelable);
        if (data) {
          for (d in data) {
            event[d] = data[d];
          }
        }
        return element.dispatchEvent(event);
      };

      Helper.prototype.checkBrowser = function() {
        var android, browserName, browserVersion, ios, ua;

        ua = navigator.userAgent.toLowerCase();
        ios = ua.match(/(?:iphone\sos|ip[oa]d.*os)\s([\d_]+)/);
        android = ua.match(/(android)\s+([\d.]+)/);
        browserName = !!ios ? "ios" : !!android ? "android" : "pc";
        browserVersion = (function() {
          if (!ios && !android) {
            return null;
          }
          return parseFloat((ios || android).pop().split(/\D/).join("."));
        })();
        return {
          name: browserName,
          version: browserVersion,
          isLegacy: !!android && browserVersion < 3
        };
      };

      Helper.prototype.checkSupport = function() {
        var hasTransform, hasTransform3d, hasTransition;

        hasTransform3d = this.hasProp(["perspectiveProperty", "WebkitPerspective", "MozPerspective", "msPerspective", "OPerspective"]);
        hasTransform = this.hasProp(["transformProperty", "WebkitTransform", "MozTransform", "msTransform", "OTransform"]);
        hasTransition = this.hasProp(["transitionProperty", "WebkitTransitionProperty", "MozTransitionProperty", "msTransitionProperty", "OTransitionProperty"]);
        return {
          touch: "ontouchstart" in window,
          eventListener: "addEventListener" in window,
          transform3d: hasTransform3d,
          transform: hasTransform,
          transition: hasTransition,
          cssAnimation: hasTransform3d || hasTransform && hasTransition ? true : false
        };
      };

      Helper.prototype.checkTouchEvents = function() {
        var hasTouch;

        hasTouch = this.checkSupport().touch;
        return {
          start: hasTouch ? "touchstart" : "mousedown",
          move: hasTouch ? "touchmove" : "mousemove",
          end: hasTouch ? "touchend" : "mouseup"
        };
      };

      Helper.prototype.getDeviceWidth = function() {
        return window.innerWidth;
      };

      Helper.prototype.getParentNodeWidth = function(element) {
        if (element === void 0) {
          throw new Error("Element Not Found");
        }
        return element.parentNode.offsetWidth;
      };

      Helper.prototype.getElementWidth = function(element) {
        var border, boxSizingVal, css, hasBoxSizing, padding, styleParser, width;

        if (element === void 0) {
          throw new Error("Element Not Found");
        }
        css = window.getComputedStyle(element);
        boxSizingVal = void 0;
        hasBoxSizing = (function() {
          var prop, properties, _i, _len;

          properties = ["-webkit-box-sizing", "-moz-box-sizing", "-o-box-sizing", "-ms-box-sizing", "box-sizing"];
          for (_i = 0, _len = properties.length; _i < _len; _i++) {
            prop = properties[_i];
            if (element.style[prop] !== void 0) {
              boxSizingVal = element.style[prop];
              return true;
            }
          }
          return false;
        })();
        if (!hasBoxSizing || boxSizingVal === "content-box") {
          styleParser = function(props) {
            var i, prop, total, value, _i, _len;

            value = [];
            total = 0;
            for (i = _i = 0, _len = props.length; _i < _len; i = ++_i) {
              prop = props[i];
              if (css[prop]) {
                value[i] = parseFloat(css[props[0]].match(/\d+/));
                total += value[i];
              }
            }
            return total;
          };
          border = styleParser(["border-right-width", "border-left-width"]);
          padding = styleParser(["padding-right", "padding-left"]);
          width = element.scrollWidth + border + padding;
          return width;
        } else if (element.scrollWidth === 0) {
          width = parseFloat(element.style.width.match(/\d+/));
          if (!element.style.boxSizing || !element.style.webkitBoxSizing) {
            if (element.style.paddingRight) {
              width += parseFloat(element.style.paddingRight.match(/\d+/));
            }
            if (element.style.paddingLeft) {
              width += parseFloat(element.style.paddingLeft.match(/\d+/));
            }
          }
          return width;
        } else {
          width = element.scrollWidth;
          return width;
        }
      };

      Helper.prototype.getTranslate = function(use3d, x, y, z) {
        if (use3d == null) {
          use3d = true;
        }
        if (y == null) {
          y = 0;
        }
        if (z == null) {
          z = 0;
        }
        if (this.opts.use3d) {
          return "translate3d(" + x + "px, 0, 0)";
        } else {
          return "translate(" + x + "px, 0)";
        }
      };

      Helper.prototype.getTransitionEndEventName = function() {
        var browser, match, ua, version;

        ua = window.navigator.userAgent.toLowerCase();
        match = /(webkit)[ \/]([\w.]+)/.exec(ua || /(firefox)[ \/]([\w.]+)/.exec(ua || /(msie) ([\w.]+)/.exec(ua || /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua || []))));
        browser = match[1];
        version = parseFloat(match[2]);
        if (browser === "msie" && version >= 10) {
          browser = "modernIE";
        }
        switch (browser) {
          case "webkit":
            return "webkitTransitionEnd";
          case "opera":
            return "oTransitionEnd";
          case "firefox":
          case "modernIE":
            return "transitionend";
          default:
            return void 0;
        }
      };

      return Helper;

    })();
  });

  namespace("Flickable", function() {
    var Core;

    return Core = (function() {
      var helper;

      helper = new Flickable.Helper();

      function Core(element, options, callback) {
        var eventName,
          _this = this;

        if (!element) {
          throw new Error("Element Not Found");
        } else if (typeof element === "object" && element.length) {
          element = element[0];
        }
        this.el = typeof element === "string" ? document.querySelector(element) : element;
        this.opts = options || {};
        this.helper = helper;
        this.browser = this.helper.checkBrowser();
        this.support = this.helper.checkSupport();
        this.events = this.helper.checkTouchEvents();
        this.opts.use3d = this.opts.disable3d ? false : this.support.transform3d;
        this.opts.useJsAnimate = false;
        this.opts.disableTouch = this.opts.disableTouch || false;
        this.opts.disable3d = this.opts.disable3d || false;
        this.opts.setWidth = this.opts.setWidth || true;
        this.opts.fitWidth = this.opts.fitWidth || false;
        this.opts.autoPlay = this.opts.autoPlay || false;
        this.opts.interval = this.opts.interval || 6600;
        this.opts.loop = this.opts.loop || (this.opts.autoPlay ? true : false);
        this.opts.transition = this.opts.transition || {};
        this.opts.transition = {
          timingFunction: this.opts.transition["timingFunction"] || "cubic-bezier(0.23, 1, 0.32, 1)",
          duration: (function() {
            return _this.opts.transition["duration"] || (_this.browser.isLegacy ? "200ms" : "330ms");
          })()
        };
        this.currentPoint = this.opts.currentPoint || 0;
        this.maxPoint = this.currentX = this.maxX = 0;
        this.gestureStart = this.moveReady = this.scrolling = this.didCloneNode = false;
        this.startTime = this.timerId = this.basePageX = this.startPageX = this.startPageY = this.distance = this.childNodes = this.visibleSize = null;
        if (this.support.cssAnimation && !this.browser.isLegacy) {
          this.helper.setStyle(this.el, {
            transitionProperty: this.helper.getCSSVal("transform"),
            transitionDuration: "0ms",
            transitionTimingFunction: this.opts.transition["timingFunction"],
            transform: this._getTranslate(0)
          });
        } else if (this.browser.isLegacy) {
          this.helper.setStyle(this.el, {
            position: "relative",
            left: "0px",
            transitionProperty: "left",
            transitionDuration: "0ms",
            transitionTimingFunction: this.opts.transition["timingFunction"]
          });
        } else {
          this.helper.setStyle(this.el, {
            position: "relative",
            left: "0px"
          });
        }
        if (this.support.eventListener) {
          document.addEventListener("gesturestart", function() {
            _this.gestureStart = true;
          }, false);
          document.addEventListener("gestureend", function() {
            _this.gestureStart = false;
          }, false);
        }
        if (this.opts.autoPlay) {
          this._startAutoPlay();
          window.addEventListener("blur", function() {
            return _this._clearAutoPlay();
          }, false);
          window.addEventListener("focus", function() {
            return _this._startAutoPlay();
          }, false);
        }
        if (this.opts.fitWidth) {
          eventName = this.browser.name === "pc" ? "resize" : "orientationchange";
          window.addEventListener(eventName, function() {
            return _this.refresh();
          }, false);
        }
        this.el.addEventListener(this.events.start, this, false);
        if (callback && typeof callback !== "function") {
          throw new TypeError("Must be a Function");
        } else if (callback) {
          callback();
        }
        if (this.opts.loop) {
          this._cloneNode();
        }
        this.refresh();
      }

      Core.prototype.handleEvent = function(event) {
        switch (event.type) {
          case this.events.start:
            return this._touchStart(event);
          case this.events.move:
            return this._touchMove(event);
          case this.events.end:
            return this._touchEnd(event);
          case "click":
            return this._click(event);
        }
      };

      Core.prototype.refresh = function() {
        var getMaxPoint,
          _this = this;

        if (this.opts.fitWidth) {
          this._setTotalWidth(this.helper.getParentNodeWidth(this.el));
        } else if (this.opts.setWidth) {
          this._setTotalWidth();
        }
        getMaxPoint = function() {
          var node, ret, _i, _len, _ref1;

          ret = 0;
          _ref1 = _this.el.childNodes;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            node = _ref1[_i];
            if (node.nodeType === 1) {
              ret++;
            }
          }
          if (ret > 0) {
            ret--;
          }
          return ret;
        };
        this.maxPoint = this.opts.maxPoint === void 0 ? getMaxPoint() : this.opts.maxPoint;
        this.distance = this.opts.distance === void 0 ? this.el.scrollWidth / (this.maxPoint + 1) : this.opts.distance;
        this.maxX = -this.distance * this.maxPoint;
        return this.moveToPoint();
      };

      Core.prototype.hasPrev = function() {
        return this.currentPoint > 0;
      };

      Core.prototype.hasNext = function() {
        return this.currentPoint < this.maxPoint;
      };

      Core.prototype.toPrev = function() {
        if (!this.hasPrev()) {
          return;
        }
        return this.moveToPoint(this.currentPoint--);
      };

      Core.prototype.toNext = function() {
        if (!this.hasNext()) {
          return;
        }
        return this.moveToPoint(this.currentPoint++);
      };

      Core.prototype.moveToPoint = function(point, duration) {
        var beforePoint;

        if (point == null) {
          point = this.currentPoint;
        }
        if (duration == null) {
          duration = this.opts.transition["duration"];
        }
        beforePoint = this.currentPoint;
        this.currentPoint = point < 0 ? 0 : point > this.maxPoint ? this.maxPoint : parseInt(point, 10);
        if (this.support.cssAnimation) {
          this.helper.setStyle(this.el, {
            transitionDuration: duration
          });
        } else {
          this.opts.useJsAnimate = true;
        }
        this._setX(-this.currentPoint * this.distance, duration);
        if (beforePoint !== this.currentPoint) {
          this.helper.triggerEvent(this.el, "flpointmove", true, false);
          if (this.opts.loop) {
            return this._loop();
          }
        }
      };

      Core.prototype._setX = function(x, duration) {
        if (duration == null) {
          duration = this.opts.transition["duration"];
        }
        this.currentX = x;
        if (this.support.cssAnimation && !this.browser.isLegacy) {
          return this.helper.setStyle(this.el, {
            transform: this._getTranslate(x)
          });
        } else if (this.browser.isLegacy || !this.otps.useJsAnimate) {
          this.el.style.left = "" + x + "px";
        } else {
          return this._jsAnimate(x, duration);
        }
      };

      Core.prototype._touchStart = function(event) {
        if (this.opts.disableTouch || this.gestureStart) {
          return;
        }
        if (this.opts.loop) {
          if (this.currentPoint === this.maxPoint) {
            this.moveToPoint(1, 0);
          } else if (this.currentPoint === 0) {
            this.moveToPoint(this.maxPoint - 1, 0);
          }
        }
        this.el.addEventListener(this.events.move, this, false);
        document.addEventListener(this.events.end, this, false);
        if (!this.support.touch) {
          event.preventDefault();
        }
        if (this.support.cssAnimation) {
          this.helper.setStyle(this.el, {
            transitionDuration: "0ms"
          });
        } else {
          this.opts.useJsAnimate = false;
        }
        this.scrolling = true;
        this.moveReady = false;
        this.startPageX = this.helper.getPage(event, "pageX");
        this.startPageY = this.helper.getPage(event, "pageY");
        this.basePageX = this.startPageX;
        this.directionX = 0;
        this.startTime = event.timeStamp;
        return this.helper.triggerEvent(this.el, "fltouchstart", true, false);
      };

      Core.prototype._touchMove = function(event) {
        var deltaX, deltaY, distX, isPrevent, newX, pageX, pageY;

        if (this.opts.autoPlay) {
          this._clearAutoPlay();
        }
        if (!(this.scrolling || this.gestureStart)) {
          return;
        }
        pageX = this.helper.getPage(event, "pageX");
        pageY = this.helper.getPage(event, "pageY");
        if (this.moveReady) {
          event.preventDefault();
          event.stopPropagation();
          distX = pageX - this.basePageX;
          newX = this.currentX + distX;
          if (newX >= 0 || newX < this.maxX) {
            newX = Math.round(this.currentX + distX / 3);
          }
          this.directionX = distX === 0 ? this.directionX : distX > 0 ? -1 : 1;
          isPrevent = !this.helper.triggerEvent(this.el, "fltouchmove", true, true, {
            delta: distX,
            direction: this.directionX
          });
          if (isPrevent) {
            this._touchAfter({
              moved: false,
              originalPoint: this.currentPoint,
              newPoint: this.currentPoint,
              cancelled: true
            });
          } else {
            this._setX(newX);
          }
        } else {
          deltaX = Math.abs(pageX - this.startPageX);
          deltaY = Math.abs(pageY - this.startPageY);
          if (deltaX > 5) {
            event.preventDefault();
            event.stopPropagation();
            this.moveReady = true;
            this.el.addEventListener("click", this, true);
          } else if (deltaY > 5) {
            this.scrolling = false;
          }
        }
        this.basePageX = pageX;
        if (this.opts.autoPlay) {
          return this._startAutoPlay();
        }
      };

      Core.prototype._touchEnd = function(event) {
        var newPoint,
          _this = this;

        this.el.removeEventListener(this.events.move, this, false);
        document.removeEventListener(this.events.end, this, false);
        if (!this.scrolling) {
          return;
        }
        newPoint = (function() {
          var point;

          point = -_this.currentX / _this.distance;
          if (_this.directionX > 0) {
            return Math.ceil(point);
          } else if (_this.directionX < 0) {
            return Math.floor(point);
          } else {
            return Math.round(point);
          }
        })();
        if (newPoint < 0) {
          newPoint = 0;
        } else if (newPoint > this.maxPoint) {
          newPoint = this.maxPoint;
        }
        this._touchAfter({
          moved: newPoint !== this.currentPoint,
          originalPoint: this.currentPoint,
          newPoint: newPoint,
          cancelled: false
        });
        return this.moveToPoint(newPoint);
      };

      Core.prototype._touchAfter = function(params) {
        var _this = this;

        this.scrolling = false;
        this.moveReady = false;
        setTimeout(function() {
          return _this.el.removeEventListener("click", _this, true);
        }, 200);
        return this.helper.triggerEvent(this.el, "fltouchend", true, false, params);
      };

      Core.prototype._click = function(event) {
        event.stopPropagation();
        return event.preventDefault();
      };

      Core.prototype._getTranslate = function(x) {
        if (this.opts.use3d) {
          return "translate3d(" + x + "px, 0, 0)";
        } else {
          return "translate(" + x + "px, 0)";
        }
      };

      Core.prototype._cloneNode = function() {
        var i, insertNode, insertedCount, nodeAry, parentNodeWidth,
          _this = this;

        if (!(this.opts.loop || this.didCloneNode)) {
          return;
        }
        nodeAry = (function() {
          var node, ret, _i, _len, _ref1;

          ret = [];
          _ref1 = _this.el.childNodes;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            node = _ref1[_i];
            if (node.nodeType === 1) {
              ret.push(node);
            }
          }
          return ret;
        })();
        parentNodeWidth = this.helper.getParentNodeWidth(this.el);
        insertedCount = 0;
        insertNode = function(start, end) {
          var firstItem, lastItem;

          firstItem = nodeAry[start];
          lastItem = nodeAry[nodeAry.length - end];
          _this.el.insertBefore(lastItem.cloneNode(true), nodeAry[0]);
          return _this.el.appendChild(firstItem.cloneNode(true));
        };
        this.childNodes = nodeAry;
        this.visibleSize = (parseInt(parentNodeWidth / nodeAry[0].offsetWidth, 10)) + 1;
        while (insertedCount < this.visibleSize) {
          i = insertedCount;
          insertNode(i, this.visibleSize - i);
          insertedCount++;
        }
        this.currentPoint = this.visibleSize;
        this.didCloneNode = true;
      };

      Core.prototype._startAutoPlay = function() {
        var interval, toNextFn,
          _this = this;

        if (!this.opts.autoPlay) {
          return;
        }
        toNextFn = function() {
          return _this.toNext();
        };
        interval = this.opts.interval;
        return (function() {
          _this.timerId = setInterval(toNextFn, interval);
        })();
      };

      Core.prototype._clearAutoPlay = function() {
        return clearInterval(this.timerId);
      };

      Core.prototype._setTotalWidth = function(width) {
        var childNodes, itemAry, itemWidth, node, totalWidth, _i, _len;

        if (width && typeof width !== "number") {
          throw new TypeError("Must be a Number");
        }
        childNodes = this.el.childNodes;
        itemAry = childNodes.length !== 0 ? [] : [this.el];
        for (_i = 0, _len = childNodes.length; _i < _len; _i++) {
          node = childNodes[_i];
          if (node.nodeType === 1) {
            itemAry.push(node);
          }
        }
        itemWidth = width ? width : this.helper.getElementWidth(itemAry[0]);
        totalWidth = itemAry.length * itemWidth;
        this.el.style.width = "" + totalWidth + "px";
      };

      Core.prototype._loop = function() {
        var clearTime, smartLoop, timerId, transitionEndEventName,
          _this = this;

        clearTime = this.opts.interval / 2;
        console.log("### currnetPoint  %s", this.currentPoint);
        smartLoop = function() {
          switch (_this.currentPoint) {
            case 4:
              return _this.moveToPoint(12, 0);
            case 3:
              return _this.moveToPoint(11, 0);
            case 2:
              return _this.moveToPoint(10, 0);
            case 1:
              return _this.moveToPoint(9, 0);
            case 0:
              return _this.moveToPoint(8, 0);
            case 13:
              return _this.moveToPoint(5, 0);
            case 14:
              return _this.moveToPoint(6, 0);
            case 15:
              return _this.moveToPoint(7, 0);
            case 16:
              return _this.moveToPoint(8, 0);
            case 17:
              return _this.moveToPoint(9, 0);
          }
        };
        transitionEndEventName = this.helper.getTransitionEndEventName();
        if (transitionEndEventName !== void 0) {
          this.el.addEventListener(transitionEndEventName, smartLoop, false);
          return setTimeout(function() {
            return _this.el.removeEventListener(transitionEndEventName, smartLoop, false);
          }, clearTime);
        } else {
          timerId = smartLoop;
          return clearTimeout(function() {
            return smartLoop();
          }, clearTime);
        }
      };

      Core.prototype._jsAnimate = function(x, duration) {
        var begin, easing, from, timer, to;

        begin = +new Date();
        from = parseInt(this.el.style.left, 10);
        to = x;
        duration = parseInt(duration, 10 || this.opts.transition["duration"]);
        easing = function(time, duration) {
          return -(time /= duration) * (time - 2);
        };
        timer = setInterval(function() {
          var now, pos, time;

          time = new Date() - begin;
          if (time > duration) {
            clearInterval(timer);
            now = to;
          } else {
            pos = easing(time, duration);
            now = pos * (to - from) + from;
          }
          this.el.style.left = "" + now + "px";
        }, 10);
      };

      Core.prototype.destroy = function() {
        if (this.opts.autoPlay) {
          this._clearAutoPlay();
        }
        return this.el.removeEventListener(this.events.start, this, false);
      };

      return Core;

    })();
  });

  root.Flickable = Flickable.Core;

}).call(this);
