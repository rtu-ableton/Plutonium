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

# ╔═╡ 05abd698-994a-11eb-3ea6-95ae4c538c0d
@bind dims html"""
<canvas width="200" height="200" style="position: relative"></canvas>

<script>
// 🐸 `currentScript` is the current script tag - we use it to select elements 🐸 //
const canvas = currentScript.parentElement.querySelector("canvas")
const ctx = canvas.getContext("2d")

class Dot {
  constructor(x, y) {
    this.x = x;
    this.y = y;
	this.held = false;
	this.hovered = false;
  }
}

var dotSize = 6

var dotHeld = false
var dotHovered = false

var dotX = 80
var dotY = 40

function ondrag(e){
	dotX = e.layerX
	dotY = e.layerY
	// 🐸 We send the value back to Julia 🐸 //
	canvas.value = [dotX, dotY]
	canvas.dispatchEvent(new CustomEvent("input"))

	drawDotLines();

}

function drawDotLines(){
	// BG
	ctx.fillStyle = '#ffecec'
	ctx.fillRect(0, 0, 200, 200)

	ctx.beginPath();
	ctx.lineWidth = "2";
	ctx.strokeStyle = "green"; // Green path
	ctx.moveTo(dotX, dotY);
	ctx.lineTo(200, 200);
	ctx.stroke(); // Draw it

	ctx.beginPath();
	ctx.lineWidth = "2";
	ctx.strokeStyle = "green"; // Green path
	ctx.moveTo(0, 0);
	ctx.lineTo(dotX, dotY);
	ctx.stroke(); // Draw it

	ctx.fillStyle = dotHovered ? "white" : "red"
	ctx.fillRect(dotX - dotSize/2, dotY - dotSize/2, dotSize, dotSize)
}

function detectHover(e){

	if (e.layerX > dotX - dotSize 
		&& e.layerY > dotY - dotSize
		&& e.layerX < dotX + dotSize 
		&& e.layerY < dotY + dotSize){
		dotHovered = true;
	} else {
		dotHovered = false;
	}
	drawDotLines();

}

function newDot(e){
	
}

canvas.onmousedown = e => {
	if (dotHovered)
	{
		dotHeld = true;
		drawDotLines();
	}
	else
	{
		newDot(e);
	}
}

canvas.onmouseup = e => {
	dotHeld = false;
	drawDotLines();
}

canvas.onmousemove = e => {
	if (dotHeld)
	{
		ondrag(e)
	}
	detectHover(e);
}

// Fire a fake mousemoveevent to show something
ondrag({layerX: 130, layerY: 160})

</script>
"""

# ╔═╡ f861c6c4-a6bc-47a1-ad7f-ae2538582316


# ╔═╡ e318282a-2ff9-4174-868f-7a668862181f


# ╔═╡ 502139d5-9218-448e-9b0e-5e193e1a8886


# ╔═╡ 3722053a-45f7-463f-a454-852adcd5249b


# ╔═╡ 4082b4e1-e7e0-4a65-808b-7d60d8356b44


# ╔═╡ f50dc0c7-32a2-46ba-b8ac-2ed94579b44f


# ╔═╡ 6f8a6b24-32da-44dd-9a1e-898bc34b99fe


# ╔═╡ b22fddb2-d606-4906-82ff-7877dbeeb956


# ╔═╡ 14a3fb2e-994a-11eb-2e0b-17202758cd52


# ╔═╡ 0fcdc636-994a-11eb-1350-3fb2ab0fa767


# ╔═╡ Cell order:
# ╠═05abd698-994a-11eb-3ea6-95ae4c538c0d
# ╠═f861c6c4-a6bc-47a1-ad7f-ae2538582316
# ╠═e318282a-2ff9-4174-868f-7a668862181f
# ╠═502139d5-9218-448e-9b0e-5e193e1a8886
# ╠═3722053a-45f7-463f-a454-852adcd5249b
# ╠═4082b4e1-e7e0-4a65-808b-7d60d8356b44
# ╠═f50dc0c7-32a2-46ba-b8ac-2ed94579b44f
# ╠═6f8a6b24-32da-44dd-9a1e-898bc34b99fe
# ╠═b22fddb2-d606-4906-82ff-7877dbeeb956
# ╠═14a3fb2e-994a-11eb-2e0b-17202758cd52
# ╠═0fcdc636-994a-11eb-1350-3fb2ab0fa767
