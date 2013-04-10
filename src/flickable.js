// Generated by CoffeeScript 1.6.2
define(["../src/helper"], function(Helper) {
  return (function(global, document) {
    "use strict";
    var Flickable;

    return Flickable = (function() {
      function Flickable(el, opts) {
        if (opts == null) {
          opts = {};
        }
        this.el = el;
        this.helper = new Helper();
        this.support = this.helper.checkSupport();
        this.events = {
          touchStart: this.support.touch ? "touchstart" : "mousedown",
          touchMove: this.support.touch ? "touchmove" : "mousemove",
          touchEnd: this.support.touch ? "touchend" : "mouseup"
        };
        console.log(this.support.touch);
        console.log(this.support.transform3d);
        if (typeof this.el === "string") {
          this.el = document.querySelector(el);
        } else if (!this.el) {
          throw new Error("Element Not Found");
        }
        opts = opts || {};
        this.distance = !opts.distance ? null : opts.distance;
        this.maxPoint = !opts.maxPoint ? null : opts.maxPoint;
        opts.transition = opts.transition || {};
        this.transition = {
          duration: !opts.transition["duration"] ? "330ms" : opts.transition["duration"],
          timingFunction: !opts.transition["timingFunction"] ? "cubic-bezier(0, 0, 0, 0.25, 1)" : opts.transition["timingFunction"]
        };
        this.currentPoint = 0;
        this.currentX = 0;
        this.el.addEventListener(this.events.touchStart, this, false);
        return this;
      }

      Flickable.prototype.handleEvent = function(event) {
        switch (event["typeof"]) {
          case touchStartEvent:
            return this._touchStart(event);
          case touchMoveEvent:
            return this._touchMove(event);
          case touchEndEvent:
            return this._touchEnd(event);
          case "click":
            return this._click(event);
        }
      };

      Flickable.prototype.refresh = function() {};

      Flickable.prototype._touchStart = function(event) {};

      Flickable.prototype._touchMove = function(event) {};

      Flickable.prototype._touchEnd = function(event) {};

      Flickable.prototype._click = function(event) {
        event.stopPropagation();
        return event.preventDefault();
      };

      Flickable.prototype._checkSupport = function() {
        var hasTransform, hasTransform3d, hasTransition;

        hasTransform3d = this.helper.hasProp(["perspectiveProperty", "WebkitPerspective", "MozPerspective", "msPerspective", "OPerspective"]);
        hasTransform = this.helper.hasProp(["transformProperty", "WebkitTransform", "MozTransform", "msTransform", "OTransform"]);
        hasTransition = this.helper.hasProp(["transitionProperty", "WebkitTransitionProperty", "MozTransitionProperty", "msTransitionProperty", "OTransitionProperty"]);
        return {
          touch: "ontouchstart" in global,
          transform3d: hasTransform3d,
          transform: hasTransform,
          transition: hasTransition,
          cssAnimation: (function() {
            if (hasTransform3d || hasTransform && hasTransition) {
              return true;
            } else {
              return false;
            }
          })()
        };
      };

      return Flickable;

    })();
  })(this, this.document);
});