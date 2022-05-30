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

# ╔═╡ fb8785cd-565a-42d8-bffe-83f9f9b9a2b6
import Pkg; Pkg.add("PlutoUI")

# ╔═╡ 286828a8-fb5c-4538-b0ad-d38c558623e0
Pkg.add("DataStructures")

# ╔═╡ 66fb87f2-d356-11ea-2f32-9369eb3e12c7
begin
	using PlutoUI, Plots, DataStructures
	gr()
end;

# ╔═╡ eafc4bc6-dec3-4154-a2de-7030122054bf
md"""
This ntebook demos a scrolling plot of a random walk and displays the framerate.
Seems to be about 20fps, which is OK.
"""

# ╔═╡ 8ad7ccd0-d359-11ea-1b9b-cbd441322c19
begin
	ticks_per_sec =20
	ΔT = 1/ticks_per_sec
	last_time = [0.0]
	buffsize=500
	cb = CircularBuffer{Float64}(buffsize)
	cbt = CircularBuffer{Float64}(buffsize)
	fill!(cb,0.0)
	fill!(cbt,0.0)
end;

# ╔═╡ 6f7e7c70-d356-11ea-1570-61e70b58a488
@bind ticks Clock(ΔT,true)

# ╔═╡ b0e502d0-d359-11ea-0fd7-a74a05706fdb
begin
	ticks
	plot(cb,label="randwalk",leg=:left)
	plot!(cbt,label="framerate")
end

# ╔═╡ f4134320-d357-11ea-2871-05a13a891da2
begin
	ticks
	new_val = cb[end]+randn()
	push!(cb, new_val)
	new_time=time()
	delta = new_time-last_time[1]
	last_time[1]=new_time
	push!(cbt,1/delta)
end;

# ╔═╡ Cell order:
# ╠═eafc4bc6-dec3-4154-a2de-7030122054bf
# ╠═fb8785cd-565a-42d8-bffe-83f9f9b9a2b6
# ╠═286828a8-fb5c-4538-b0ad-d38c558623e0
# ╠═66fb87f2-d356-11ea-2f32-9369eb3e12c7
# ╠═6f7e7c70-d356-11ea-1570-61e70b58a488
# ╠═b0e502d0-d359-11ea-0fd7-a74a05706fdb
# ╠═8ad7ccd0-d359-11ea-1b9b-cbd441322c19
# ╠═f4134320-d357-11ea-2871-05a13a891da2
