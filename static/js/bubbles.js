var width = $(window).width()/2, height = $(window).height();
var svg = d3.select("#bubbles")
	.append("svg")
	.attr("width", width)
	.attr("height", height);

var bubble = d3.layout.pack()
    .sort(null)
    .size([width, height])
    .padding(1.5);

data = {
    "bubbles": [
        {
            "id": 1,
            "name": "Henry",
            "value": 100
        },
        {
            "id": 2,
            "name": "Nick",
            "value": -50
        }
    ]
} 

d3.json(data, function(error, root) {
	//var circle = svg.selectAll("circle")
		//.data([10,20,30,40,50])
		//.data(data)
		//.enter().append("circle")
		//.style("stroke", "gray")
		//.style("fill", "black")
		//.attr("r", Math.sqrt)
		//.attr("cx", function(d) { return d; })
		//.attr("cy", 20);
	var node = svg.selectAll(".node")
	      .data(bubble.nodes(classes(root))
	      .filter(function(d) { return !d.children; }))
	    .enter().append("g")
	      .attr("class", "node")
	      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

	  node.append("title")
	      .text(function(d) { return d.className + ": " + format(d.value); });

	  node.append("circle")
	      .attr("r", function(d) { return d.r; })
	      .style("fill", function(d) { return color(d.packageName); });

	  node.append("text")
	      .attr("dy", ".3em")
	      .style("text-anchor", "middle")
	      .text(function(d) { return d.className.substring(0, d.r / 3); });
});

// Returns a flattened hierarchy containing all leaf nodes under the root.
function classes(root) {
  var classes = [];

  function recurse(name, node) {
    if (node.bubbles) node.bubbles.forEach(function(child) { recurse(node.name, child); });
    else classes.push({packageName: name, className: node.name, value: node.size});
  }

  recurse(null, root);
  return {bubbles: values};
}

d3.select(self.frameElement).style("height", height + "px");
