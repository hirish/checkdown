var svg = d3.select("#bubbles")
	.append("svg")
	.attr("width", $(window).width()/2)
	.attr("height", $(window).height());

var circle = svg.selectAll("circle")
	.data([10,20,30,40,50])
	.enter().append("circle")
	.style("stroke", "gray")
	.style("fill", "black")
	.attr("r", Math.sqrt)
	.attr("cx", function(d) { return d; })
	.attr("cy", 20);
