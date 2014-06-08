var Axis, LineGraph, PointCalculator, Utils;

PointCalculator = {
  x: function(valueX) {
    var maxX, minX, normed, position, xLen, _ref;
    _ref = Utils.minMax(this.props.valueLists, 'x'), minX = _ref[0], maxX = _ref[1];
    xLen = this.props.width - (2 * this.props.margin) - this.props.leftOffset;
    normed = valueX - minX;
    position = parseInt(xLen * normed / (maxX - minX));
    return position + this.props.leftOffset + this.props.margin;
  },
  y: function(valueY) {
    var maxY, minY, normed, position, yLen, _ref;
    _ref = Utils.minMax(this.props.valueLists, 'y', this.props.normaliseYAxis), minY = _ref[0], maxY = _ref[1];
    yLen = this.props.height - (2 * this.props.margin);
    normed = valueY - minY;
    position = parseInt(yLen * normed / (maxY - minY));
    return this.props.margin + yLen - position;
  }
};

Utils = {
  minMax: function(valueLists, dim, normalize) {
    var absMax, max, min;
    if (normalize == null) {
      normalize = false;
    }
    min = _.min(_.pluck(_.flatten(valueLists), dim));
    max = _.max(_.pluck(_.flatten(valueLists), dim));
    if (normalize) {
      absMax = Math.max(Math.abs(min), Math.abs(max));
      return [-absMax, absMax];
    } else {
      return [min, max];
    }
  }
};

LineGraph = React.createClass({
  mixins: [PointCalculator],
  getDefaultProps: function() {
    return {
      valueLists: [],
      height: 200,
      width: 600,
      pointRadius: 4,
      leftOffset: 7,
      margin: 10,
      normalizeYAxis: false
    };
  },
  render: function() {
    var negativeFills, negativePaths, negativePoints, positiveFills, positivePaths, positivePoints;
    positivePoints = this.props.valueLists.map((function(_this) {
      return function(values) {
        return React.DOM.g({
          className: "fill colour1 positive"
        }, _this.generatePoints(values));
      };
    })(this));
    negativePoints = this.props.valueLists.map((function(_this) {
      return function(values) {
        return React.DOM.g({
          className: "fill colour2 negative"
        }, _this.generatePoints(values));
      };
    })(this));
    positivePaths = this.props.valueLists.map((function(_this) {
      return function(values) {
        return React.DOM.path({
          className: "colour1 positive",
          d: _this.generatePath(values)
        });
      };
    })(this));
    negativePaths = this.props.valueLists.map((function(_this) {
      return function(values) {
        return React.DOM.path({
          className: "colour2 negative",
          d: _this.generatePath(values)
        });
      };
    })(this));
    positiveFills = this.props.valueLists.map((function(_this) {
      return function(values) {
        return React.DOM.path({
          className: "fill colour1 positive",
          d: _this.positiveFill(values)
        });
      };
    })(this));
    negativeFills = this.props.valueLists.map((function(_this) {
      return function(values) {
        return React.DOM.path({
          className: "fill colour2 negative",
          d: _this.positiveFill(values)
        });
      };
    })(this));
    return React.DOM.svg({
      className: "reactGraph",
      width: this.props.width,
      height: this.props.height
    }, React.DOM.clippath({
      id: "positive"
    }, React.DOM.rect({
      x: 0,
      y: 0,
      width: this.props.width,
      height: this.y(0)
    })), React.DOM.clippath({
      id: "negative"
    }, React.DOM.rect({
      x: 0,
      y: this.y(0),
      width: this.props.width,
      height: this.y(0)
    })), positiveFills, negativeFills, positivePaths, negativePaths, this.transferPropsTo(Axis()), positivePoints, negativePoints);
  },
  generatePath: function(values) {
    var sections;
    sections = values.map((function(_this) {
      return function(value) {
        return "L " + (_this.x(value.x)) + " " + (_this.y(value.y));
      };
    })(this));
    return sections.reduce(((function(_this) {
      return function(y, section) {
        return y + " " + section;
      };
    })(this)), "M " + (this.x(0)) + " " + (this.y(0)) + " ");
  },
  positiveFill: function(values) {
    var connectedPath, path;
    path = this.generatePath(values);
    return connectedPath = path + (" V " + (this.y(0)) + " H " + (this.x(0)));
  },
  generatePoints: function(values) {
    return values.map((function(_this) {
      return function(value) {
        return React.DOM.circle({
          cx: _this.x(value.x),
          cy: _this.y(value.y),
          r: _this.props.pointRadius
        });
      };
    })(this));
  }
});

Axis = React.createClass({
  mixins: [PointCalculator],
  render: function() {
    var axis, path;
    path = "M " + (this.props.leftOffset + this.props.margin) + " " + this.props.margin;
    path += "V " + (this.props.height - this.props.margin);
    path += "M " + this.props.margin + " " + (this.y(0));
    path += "H " + (this.props.width - this.props.margin);
    return axis = React.DOM.path({
      className: "axis",
      d: path
    });
  }
});
