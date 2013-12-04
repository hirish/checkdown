getXs = (values) -> values.map (value) -> value.x
getYs = (values) -> values.map (value) -> value.y
min = (values) -> values.reduce ((s, v) -> if v > s then s else v)
max = (values) -> values.reduce ((s, v) -> if v < s then s else v)

LineGraph = React.createClass

  getInitialState: ->
    {
      valueLists: []
      minX: 0
      maxX: 100
      minY: -100
      maxY: 100
      dimY: 200
      dimX: 600
      pointRadius: 4
      leftOffset: 7
      margin: 10
    }

  componentDidMount: (node) ->
    parentX = $(node).parent().width()
    parentY = $(node).parent().height()

    dimX = if @props.width then @props.width else if @props.autoResize then parentX else @state.dimX
    dimY = if @props.height then @props.height else if @props.autoResize then parentY else @state.dimY

    if @props.autoResize
      $(window).resize => @setState({dimX: $(node).parent().width()})

    minX = min @props.valueLists.map (valueList) -> min(getXs valueList)
    maxX = max @props.valueLists.map (valueList) -> max(getXs valueList)

    minY = min @props.valueLists.map (valueList) -> min(getYs valueList)
    maxY = max @props.valueLists.map (valueList) -> max(getYs valueList)

    if @props.normaliseYAxis
      yAxisSize = Math.max Math.abs(minY), Math.abs(maxY)
      maxY = yAxisSize
      minY = -yAxisSize

    @setState minX: minX, maxX: maxX, minY: minY, maxY: maxY, dimX: dimX, dimY: dimY, valueLists: @props.valueLists

  render: ->
    positivePoints = @props.valueLists.map (values) => React.DOM.g {className: "fill colour1 positive"}, @generatePoints(values)
    negativePoints = @props.valueLists.map (values) => React.DOM.g {className: "fill colour2 negative"}, @generatePoints(values)

    positivePaths = @props.valueLists.map (values) => React.DOM.path {className: "colour1 positive", d: @generatePath values}
    negativePaths = @props.valueLists.map (values) => React.DOM.path {className: "colour2 negative", d: @generatePath values}

    positiveFills = @props.valueLists.map (values) => React.DOM.path {className: "fill colour1 positive", d: @positiveFill(values)}
    negativeFills = @props.valueLists.map (values) => React.DOM.path {className: "fill colour2 negative", d: @positiveFill(values)}

    axis = React.DOM.path({className: "axis", d: "M 5 0 V 200 M 0 100 H 625"})
    axis = React.DOM.path({className: "axis", d: @axisPath()})

    React.DOM.svg({className: "reactGraph", width: @state.dimX, height: @state.dimY},
      React.DOM.clippath({id: "positive"}, 
        React.DOM.rect({x: 0, y: 0, width: @state.dimX, height: (@y 0)})
      )
      React.DOM.clippath({id: "negative"}, 
        React.DOM.rect({x: 0, y: (@y 0), width: @state.dimX, height: (@y 0)})
      )
      positiveFills
      negativeFills
      positivePaths
      negativePaths
      axis
      positivePoints
      negativePoints
    )

  axisPath: ->
    # Y Axis
    path  = "M #{(@state.leftOffset + @state.margin)} #{@state.margin}"
    path += "V #{@state.dimY - @state.margin}"

    # X Axis
    path += "M #{@state.margin} #{@y 0}"
    path += "H #{@state.dimX - @state.margin}"

  generatePath: (values) ->
    sections = values.map (value) => "L " + (@x value.x) + " " + (@y value.y)
    sections.reduce ((y, section) => y + " " + section), "M #{@x 0} #{@y 0} "

  positiveFill: (values) ->
    path = @generatePath values
    connectedPath = path + " V #{@y 0} H #{@x 0}"

  generatePoints: (values) ->
    values.map (value) => React.DOM.circle({cx: @x(value.x), cy: @y(value.y), r: @state.pointRadius})

  x: (valueX) ->
    xLen = @state.dimX - (2*@state.margin) - @state.leftOffset
    normed = valueX - @state.minX
    position = parseInt(xLen * normed / (@state.maxX - @state.minX))
    position + @state.leftOffset + @state.margin
  y: (valueY) ->
    yLen = @state.dimY - (2 * @state.margin)
    normed = valueY - @state.minY
    position = parseInt(yLen * normed / (@state.maxY - @state.minY))
    @state.margin + yLen - position
