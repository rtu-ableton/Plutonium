### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 8caefc51-e904-4da3-8718-1f8029f5c0bb
begin
	import Pkg; Pkg.add("Interact")
	include("DSP Mentorship/utilities.jl");
end

# ╔═╡ 79d9aad8-b805-11ec-012a-2951a59354e8
using Plots


# ╔═╡ 7f49e527-9b65-4ba7-84af-2267efb8970c
using PlutoUI

# ╔═╡ 04c37537-e682-4538-8121-083115c10636
md"""
A test to see if a slider animating a 3D plot is usable at all.
"""

# ╔═╡ c524219f-c7bd-4aad-bbc0-a46eabf980c6
md"""
This demonstrates a 3D plot of a z-transform, animated via a slider changing the a coefficient.
"""

# ╔═╡ 8c617e2e-06d3-45fd-adae-05715723acf9
@bind a Slider(1:150)

# ╔═╡ a6a00721-b84a-468f-b6f1-c08cddc658d0
begin
	ω = a / 10.0
	θ=0:0.01:2*π;
	i = 0.0 + 1.0im;
	x = exp.(i * θ * ω);
	plot()
	plotComplexPlane3D(4)
	plot!(θ, real.(x), imag.(x));
end

# ╔═╡ edc2f50f-5efe-4deb-bf9f-1f87461ad03a
zTransformIIR([a / 150., 0.3], [0.5, 0.6])

# ╔═╡ Cell order:
# ╟─04c37537-e682-4538-8121-083115c10636
# ╠═79d9aad8-b805-11ec-012a-2951a59354e8
# ╠═7f49e527-9b65-4ba7-84af-2267efb8970c
# ╠═8caefc51-e904-4da3-8718-1f8029f5c0bb
# ╠═a6a00721-b84a-468f-b6f1-c08cddc658d0
# ╟─c524219f-c7bd-4aad-bbc0-a46eabf980c6
# ╠═8c617e2e-06d3-45fd-adae-05715723acf9
# ╟─edc2f50f-5efe-4deb-bf9f-1f87461ad03a
