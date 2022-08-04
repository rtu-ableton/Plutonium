### A Pluto.jl notebook ###
# v0.19.9

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
	include("utilities.jl");
end

# ╔═╡ 79d9aad8-b805-11ec-012a-2951a59354e8
using Plots


# ╔═╡ 7f49e527-9b65-4ba7-84af-2267efb8970c
using PlutoUI

# ╔═╡ 8ce99269-88db-4db2-91ad-d28b5bb5f04c
using FFTW

# ╔═╡ 04c37537-e682-4538-8121-083115c10636
md"""
### Introduction to anti-aliasing oscillator waveforms 1

- Why do simple waveforms e.g. a sawtooth alias?
- The "mathematically ideal" waveform vs. the ideal bandlimited waveform.
- The "residual": what's the difference between the ideal and the simple waveform?


"""

# ╔═╡ 2cc57524-335b-408a-90a2-786a7af9920e
function hann(N)
	n = 1:N
	return (0.5 .- 0.5 .* cos.(2 .* π .* n ./ N))
end

# ╔═╡ 6a0f1e8a-5cce-4fce-a19a-cbf207c69905
function plotDbMagSpectrum(x; kwargs...)
	windowed = x .* hann(length(x));
    xPadded = [windowed; zeros(length(x) * 3)]
    magSpec = abs.(fft(flipHalves(xPadded)))
    N = length(magSpec)
    N_2 = div(N, 2)

    x = 2 * π * [1:N_2] ./ N
    y = log10.(magSpec[1:N_2])
    plot(x, y, framestyle=:origin, ylims=[0, 2.5]; kwargs...)
end


# ╔═╡ c536b4a3-5f74-4a03-88e5-cda51587ad97
begin
		N = 1024
		FS = 44100
end

# ╔═╡ 11fa87ce-dfd6-463e-9ff8-a133e121a620
# What is the sound of 1 sine aliasing?
function sineWave(N, f, fs)
	n = 1:N
	sin.(2 * π * n * f / fs)
	
end

# ╔═╡ 891d3c89-eebe-4c2d-94b2-ca22da995f80
@bind f0 Slider(1000:FS)

# ╔═╡ c7047ec3-8a1e-4346-b1db-394dd7ab4da6
plot(sineWave(20, f0, FS), ylims=[-1.1,1.1])

# ╔═╡ abfb2346-e12f-4cbd-b5ad-2d564b543e18
plotDbMagSpectrum(sineWave(8192, f0, FS))

# ╔═╡ a6a00721-b84a-468f-b6f1-c08cddc658d0
# This function uses an accumulator that wraps when the saw's ramp is completed.
# This will alias!
function naiveSaw(N, f, fs)
	x = zeros(N)
	inc = 2 * f / fs
	accumulator = 0.0
	for n in 1:N
		accumulator += inc
		if accumulator > 1.0
			accumulator -= 2.0
		end
		x[n] = accumulator
	end
	x
end

# ╔═╡ 8c617e2e-06d3-45fd-adae-05715723acf9
@bind f1 Slider(2000:0.1:5000)

# ╔═╡ df02584a-72da-4a16-b983-25eaf5609518
plot(naiveSaw(9000, f1, FS))

# ╔═╡ ea854791-ecb9-4424-b8da-da9730fa6e6e

	# lets look at the spectrum
	plotDbMagSpectrum(naiveSaw(N, f1, FS))

# ╔═╡ 9fbe0c29-0a38-4def-979e-1488f11455cf
md"""

The fourier series of a sawtooth is an infinite sum of sinusoids of frequencies n * f, with their amplitude falling off as 1/n.

But we know we can't represent that as a sampled signal, so what is the "ideal" bandlimited sawtooth?

It would be the additive saw with the number of sinusoids being cut off as soon as the frequency goes above nyquist.
"""

# ╔═╡ 6793f805-8771-410c-96e9-04cae96cb747
# Create a bandlimited saw with K sinusoids
function additiveSaw(N, f, FS, K)
	x = zeros(N)
	ω = 2 * π * f / FS
	
	for k=1:K
		for n=1:N
			c = -2/π * (-1)^k
			x[n] += c * 1/k * sin(n * k * ω)
		end
	end
	x
end

# ╔═╡ 933a33be-c642-4218-9c27-9103c27e5f25
@bind numSinusoids Slider(1:100)

# ╔═╡ 406e15a7-7d56-4d52-9ff4-4d5533f614b8
@bind f2 Slider(100:2000)

# ╔═╡ 9e68d5f2-011a-474b-9220-e18e783c4062
plot(additiveSaw(N, f2, FS, numSinusoids), ylims=[-1.5, 1.5], linecolor="red")

# ╔═╡ 4a0965af-e3ff-4aef-993e-ad6953d2eb34
# lets look at the spectrum of the additive saw, with increasing numbers of harmonics
plotDbMagSpectrum(additiveSaw(N, f2, FS, numSinusoids), linecolor="red")


# ╔═╡ 3d9604c6-7d86-4cfe-8dfb-3630bf025c4e
md"""
So the "ideal" bandlimited saw is that where numSinusoids is just enough so that the highest sinusoid does not exceed nyquist.

The problem is that additive synthesis is expensive! Is there a way to cheaply approximate this filtered saw?
"""

# ╔═╡ 2e01ed74-20f7-4e80-8aec-7d093c779f38
md"""
### The Residual

Lets take a look at the difference between the naive saw and the bandlimited one.

The exact shape of this plot is somewhat hard to read because we're sampling so coarsely, but the idea is that most of the energy of the residual is concentrated around the discontinuities in the saw.

If you think about it the sound of aliasing is the sound of this residual - the difference between the naive saw and the ideal bandlimited one.
"""

# ╔═╡ 82081d34-607c-4439-a8c2-dc4a063cd0d8
# Create a bandlimited saw that automatically stops sinusoids going over nyquist
function bandlimitedSaw(N, f, FS)
	x = zeros(N)
	k = 1
	
	while (k * f) < FS/2.0
		for n=1:N
			x[n] += -2/(π*k) * (-1)^k * sin(2 * π * n * k * f / FS)
		end
		k += 1
	end
	x
end

# ╔═╡ d1e06dc4-1cfb-48e0-96a0-dd51d02a4938
@bind f3 Slider(200:2000)

# ╔═╡ fd68e2a3-d890-456c-b83a-a9cb571b155b
begin
residual = naiveSaw(N, f3, FS) .- bandlimitedSaw(N, f3, FS);
plot(residual[1:145], ylims=[-1.1, 1.1], linecolor="green");
end

# ╔═╡ 41b21a13-e068-44b6-823e-d24b65eac650
plotDbMagSpectrum(residual, linecolor="green")

# ╔═╡ 9a2e33f1-9d86-4dbb-9ad0-4416e67a3c60
md"""
So the idea behind BLEP (Band Limited stEP) is that we can approximate this residual "spike", just in the region where the spike is big, which only a few samples. We then subtract that approximation from the naive saw to reduce aliasing significantly.

The questions are then: 
- how do we work out a formula for the above signal?
- how do we approximate the above formula in as cheap and accurate a way possible?

To address the first question it is useful to look at integrating signals.
"""

# ╔═╡ Cell order:
# ╟─04c37537-e682-4538-8121-083115c10636
# ╟─79d9aad8-b805-11ec-012a-2951a59354e8
# ╠═7f49e527-9b65-4ba7-84af-2267efb8970c
# ╠═8ce99269-88db-4db2-91ad-d28b5bb5f04c
# ╟─2cc57524-335b-408a-90a2-786a7af9920e
# ╟─6a0f1e8a-5cce-4fce-a19a-cbf207c69905
# ╟─8caefc51-e904-4da3-8718-1f8029f5c0bb
# ╠═c536b4a3-5f74-4a03-88e5-cda51587ad97
# ╠═11fa87ce-dfd6-463e-9ff8-a133e121a620
# ╠═891d3c89-eebe-4c2d-94b2-ca22da995f80
# ╠═c7047ec3-8a1e-4346-b1db-394dd7ab4da6
# ╠═abfb2346-e12f-4cbd-b5ad-2d564b543e18
# ╠═a6a00721-b84a-468f-b6f1-c08cddc658d0
# ╠═df02584a-72da-4a16-b983-25eaf5609518
# ╠═8c617e2e-06d3-45fd-adae-05715723acf9
# ╠═ea854791-ecb9-4424-b8da-da9730fa6e6e
# ╟─9fbe0c29-0a38-4def-979e-1488f11455cf
# ╠═6793f805-8771-410c-96e9-04cae96cb747
# ╠═9e68d5f2-011a-474b-9220-e18e783c4062
# ╠═933a33be-c642-4218-9c27-9103c27e5f25
# ╠═406e15a7-7d56-4d52-9ff4-4d5533f614b8
# ╠═4a0965af-e3ff-4aef-993e-ad6953d2eb34
# ╟─3d9604c6-7d86-4cfe-8dfb-3630bf025c4e
# ╟─2e01ed74-20f7-4e80-8aec-7d093c779f38
# ╠═82081d34-607c-4439-a8c2-dc4a063cd0d8
# ╠═fd68e2a3-d890-456c-b83a-a9cb571b155b
# ╠═41b21a13-e068-44b6-823e-d24b65eac650
# ╠═d1e06dc4-1cfb-48e0-96a0-dd51d02a4938
# ╟─9a2e33f1-9d86-4dbb-9ad0-4416e67a3c60
