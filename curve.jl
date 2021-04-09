### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 35141100-2ca4-476a-b5f3-d364bcab31e6
begin
	using Plots
	gr()
end

# ╔═╡ 05abd698-994a-11eb-3ea6-95ae4c538c0d

@bind dims html"""
<canvas width="200" height="200" style="position: relative"></canvas>

<script>
// 🐸 `currentScript` is the current script tag - we use it to select elements 🐸 //
const canvas = currentScript.parentElement.querySelector("canvas")
const ctx = canvas.getContext("2d")

class Dot {
  constructor(x, y) {
	this.X = x;
	this.Y = y;
	this.held = false;
	this.hovered = false;
  }
}

var selectedDot = -1;
var dotSize = 6


var dotInital = new Dot(0,0);
var dotFinal = new Dot(200,200);

let dots = [];


function selectedDot(){
	return dots[selectedDot];
}

function ondrag(e, dot){
	dot.X = e.layerX
	dot.Y = e.layerY

	redraw();
}

function coordArray(){
	var array = [];
	dots.forEach(function(dot) {
		array.push(dot.X);
		array.push(200 - dot.Y);
	});
	return array;
}

function redraw(){
	// BG
	ctx.fillStyle = '#ffecec'
	ctx.fillRect(0, 0, 200, 200)

	dots.sort(function(dot1, dot2) {
		return dot1.X < dot2.X ? -1 : dot1.X == dot2.X ? 1 : 0;
	});

	var prevDot = dotInital;
	dots.forEach(function(dot) {
    	drawDot(dot, prevDot);
		prevDot = dot;
	});

	// 🐸 We send the value back to Julia 🐸 //
	canvas.value = coordArray();
	canvas.dispatchEvent(new CustomEvent("input"))
}

function drawDot(dot, prevDot){

	ctx.beginPath();
	ctx.lineWidth = "2";
	ctx.strokeStyle = "green"; // Green path
	ctx.moveTo(prevDot.X, prevDot.Y);
	ctx.lineTo(dot.X, dot.Y);
	ctx.stroke(); // Draw it

	ctx.fillStyle = dot.hovered ? "white" : "red"
	ctx.fillRect(dot.X - dotSize/2, dot.Y - dotSize/2, dotSize, dotSize)
}

function releaseAllDots(){
	dots.forEach(function(dot) {
		dot.held = false;
	});
}

function detectHover(e){
	dots.forEach(function(dot) {
		if (e.layerX > dot.X - dotSize 
			&& e.layerY > dot.Y - dotSize
			&& e.layerX < dot.X + dotSize 
			&& e.layerY < dot.Y + dotSize){
			dot.hovered = true;
		} else {
			dot.hovered = false;
		}
	});
	redraw();

}

function newDot(e){
	dots.push(new Dot(e.layerX, e.layerY));
}



canvas.onmousedown = e => {
	var dotWasGrabbed = false;
	dots.forEach(function(dot) {
		if (dot.hovered && !dotWasGrabbed)
		{
			dot.held = true;
			dotWasGrabbed = true;
		}
	});
	if (!dotWasGrabbed)
	{
		releaseAllDots();
		newDot(e);
	}
	redraw();
}

canvas.onmouseup = e => {
	dots.forEach(function(dot) {
		dot.held = false;
	});
	redraw();
}

canvas.onmousemove = e => {

	dots.forEach(function(dot) {
		if (dot.held)
		{
			ondrag(e, dot)
		}
	});
	detectHover(e);
	redraw();
}

redraw();

</script>
"""

# ╔═╡ 47478d29-ff99-4b97-a809-59fee152c5e3
begin
	x = dims[1:2:end]
	y = dims[2:2:end]
end

# ╔═╡ 05914563-59d5-4234-8f2d-dd9fedfdae8b
scatter(x, y, xlims=[0,200], ylims=[0,200] )

# ╔═╡ 1254b194-9382-4cec-9ddc-c9e5c232e24c


# ╔═╡ Cell order:
# ╟─35141100-2ca4-476a-b5f3-d364bcab31e6
# ╟─05abd698-994a-11eb-3ea6-95ae4c538c0d
# ╠═47478d29-ff99-4b97-a809-59fee152c5e3
# ╠═05914563-59d5-4234-8f2d-dd9fedfdae8b
# ╠═1254b194-9382-4cec-9ddc-c9e5c232e24c
