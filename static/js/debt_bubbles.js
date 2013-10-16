var diameter = 960,
	format = d3.format(",d"),
	color = d3.scale.category20c();

var bubble = d3.layout.pack()
	.sort(null)
    	.size([diameter, diameter])
    	.padding(1.5);

var svg = d3.select("debt_bubbles")
	.append("svg")
	.attr("width", diameter)
	.attr("height", diameter)
	.attr("class", "bubble");

function debt_bubbles(debts) {
	//return debts;
	var circle = svg.selectAll("circle")
		.data([1,2,3,4,5]);
}
