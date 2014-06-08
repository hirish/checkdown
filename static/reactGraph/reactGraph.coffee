PointCalculator =
  x: (valueX) ->
    [minX, maxX] = Utils.minMax(@props.valueLists, 'x')

    xLen = @props.width - (2*@props.margin) - @props.leftOffset
    normed = valueX - minX
    position = parseInt(xLen * normed / (maxX - minX))
    position + @props.leftOffset + @props.margin

  y: (valueY) ->
    [minY, maxY] = Utils.minMax(@props.valueLists, 'y', @props.normaliseYAxis)

    yLen = @props.height - (2 * @props.margin)
    normed = valueY - minY
    position = parseInt(yLen * normed / (maxY - minY))
    @props.margin + yLen - position

Utils =
  minMax: (valueLists, dim, normalize = false) ->
    min = _.min _.pluck(_.flatten(valueLists), dim)
    max = _.max _.pluck(_.flatten(valueLists), dim)

    if normalize
      absMax = Math.max Math.abs(min), Math.abs(max)
      [-absMax, absMax]
    else
      [min, max]


LineGraph = React.createClass
  mixins: [PointCalculator]

  getDefaultProps: ->
    valueLists: []
    height: 200
    width: 600
    pointRadius: 4
    leftOffset: 7
    margin: 10
    normalizeYAxis: false

  render: ->
    positivePoints = @props.valueLists.map (values) => React.DOM.g {className: "fill colour1 positive"}, @generatePoints(values)
    negativePoints = @props.valueLists.map (values) => React.DOM.g {className: "fill colour2 negative"}, @generatePoints(values)

    positivePaths = @props.valueLists.map (values) => React.DOM.path {className: "colour1 positive", d: @generatePath values}
    negativePaths = @props.valueLists.map (values) => React.DOM.path {className: "colour2 negative", d: @generatePath values}

    positiveFills = @props.valueLists.map (values) => React.DOM.path {className: "fill colour1 positive", d: @positiveFill(values)}
    negativeFills = @props.valueLists.map (values) => React.DOM.path {className: "fill colour2 negative", d: @positiveFill(values)}

    React.DOM.svg({className: "reactGraph", width: @props.width, height: @props.height},
      React.DOM.clippath({id: "positive"}, 
        React.DOM.rect({x: 0, y: 0, width: @props.width, height: (@y 0)})
      )
      React.DOM.clippath({id: "negative"}, 
        React.DOM.rect({x: 0, y: (@y 0), width: @props.width, height: (@y 0)})
      )
      positiveFills
      negativeFills
      positivePaths
      negativePaths
      @transferPropsTo Axis()
      positivePoints
      negativePoints
    )

  generatePath: (values) ->
    sections = values.map (value) => "L " + (@x value.x) + " " + (@y value.y)
    sections.reduce ((y, section) => y + " " + section), "M #{@x 0} #{@y 0} "

  positiveFill: (values) ->
    path = @generatePath values
    connectedPath = path + " V #{@y 0} H #{@x 0}"

  generatePoints: (values) ->
    values.map (value) => React.DOM.circle({cx: @x(value.x), cy: @y(value.y), r: @props.pointRadius})

Axis = React.createClass
  mixins: [PointCalculator]

  render: ->
    # Y Axis
    path  = "M #{(@props.leftOffset + @props.margin)} #{@props.margin}"
    path += "V #{@props.height - @props.margin}"

    # X Axis
    path += "M #{@props.margin} #{@y 0}"
    path += "H #{@props.width - @props.margin}"

    axis = React.DOM.path({className: "axis", d: path})
