LineGraph = React.createClass
  getInitialState: ->
    {
      valueLists: @props.valueLists
      yMin: -200
      yMax: 200
      y: 200
    }

  render: ->
    positivePoints = @props.valueLists.map (values) => React.DOM.g {className: "fill_colour1 positive"}, @generatePoints(values)
    negativePoints = @props.valueLists.map (values) => React.DOM.g {className: "fill_colour2 negative"}, @generatePoints(values)

    positivePaths = @props.valueLists.map (values) => React.DOM.path {className: "colour1 positive", d: @generatePath values}
    negativePaths = @props.valueLists.map (values) => React.DOM.path {className: "colour2 negative", d: @generatePath values}

    positiveFills = @props.valueLists.map (values) => React.DOM.path {className: "fill_colour1 positive", d: @positiveFill(values)}
    negativeFills = @props.valueLists.map (values) => React.DOM.path {className: "fill_colour2 negative", d: @positiveFill(values)}

    axis = React.DOM.path({className: "axis", d: "M 5 0 V 200 M 0 100 H 625"})

    React.DOM.svg({className: "reactGraph", width: 700, height: 210},
      positiveFills
      negativeFills
      positivePaths
      negativePaths
      axis
      positivePoints
      negativePoints
    )

  generatePath: (values) ->
    sections = values.map (value) => "L " + (@x value.x) + " " + (@y value.y)
    sections.reduce ((y, section) -> y + " " + section), "M 5 100 "

  positiveFill: (values) ->
    path = @generatePath values
    connectedPath = path + " V 100 H 5"

  generatePoints: (values) ->
    values.map (value) => React.DOM.circle({cx: @x(value.x), cy: @y(value.y), r: 3})

  x: (valueX) -> valueX + 5
  y: (valueY) ->
    normed = valueY - @state.yMin
    position = parseInt(@state.y * normed / (@state.yMax - @state.yMin))
    @state.y - position


$ ->
  console.log "Hello World"
  xs = [0, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60]
  ys = [0, 40, -150, -130, -50, -20, 40, 50, 80, 90, 100]
  values = []
  for i in [0..10]
    values.push {x:10*xs[i], y:ys[i]}
  window.v = values

  React.renderComponent LineGraph({valueLists: [values]}), $('#other')[0]
