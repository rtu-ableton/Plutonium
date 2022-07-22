# utilities for plotting complex exponentials in 3D

i = 1im;

function myTinyFft(x)
    W(m, N) = exp.(-1im * 2 * π * m / N)
    N = length(x)

    if (N == 1)
        return x
    end

    even = myTinyFft(x[1:2:N-1])
    odd = myTinyFft(x[2:2:N])

    [even; even] + W(0:N-1, N) .* [odd; odd]
end

# This function just plots a circle and some axes
function plotComplexPlane(r=1.5)

    # axes
    plot([0, 0], [-r, r], linecolor=:black, label="")
    plot!([-r, r], [0, 0], linecolor=:black, label="")

    # unit circle
    θ = 0:0.01:2*π
    expo = exp.(1im .* θ)
    plot!(real.(expo), imag(expo), xlims=(-r, r), ylims=(-r, r), linecolor=:black, size=(600, 600), label="")
    annotate!(-0.05, 1.1, text("i"))
    annotate!(-0.05, -1.1, text("-i"))
end

function plotPhasor(p, colorP=:blue, labelP="")
    n = 1:length(p)
    plot(n, real.(p), imag(p), linecolor=colorP, label=labelP)
end

function plotPhasor!(p, colorP=:black, labelP="")
    n = 1:length(p)
    plot!(n, real.(p), imag(p), linecolor=colorP, label=labelP, title="phasor")
end

# utility function  to plot the complex plane in 3D
function plotComplexPlane3D(N)
    θ = 0:0.01:2*π
    expo = exp.(1im .* θ)

    r = 1.2

    plot!([0, 0], [0, 0], [-r, r], linecolor=:black, label="")
    plot!([0, 0], [-r, r], [0, 0], linecolor=:black, label="")
    plot!(zeros(length(expo)), real.(expo), imag(expo), linecolor=:black, label="")

    # plot sample axis
    plot!([1:N], zeros(N), zeros(N), linecolor=:black, label="")
end

function plotComplexSignal3D(signal, colorP=:blue)
    plotPhasor(signal, colorP)
    plotComplexPlane3D(length(signal))
end

function formatAngle(θ)
    angle = string(θ / π)
    if length(angle) > 4
        angle = angle[1:4]
    end
    angle * "π"
end

# n is the sample index, omega the angular frequency (aka, angular rotation per sample), phi the phase offset
function phasor(n, ω, ϕ=0)
    angle = ω .* n .+ ϕ

    exp.(1im .* angle)
end

function stringf(x)
    xs = string(x)
    if length(xs) > 4
        xs = xs[1:4]
    end
    xs
end


function convolve(a, b)
    N = length(b)
    M = length(a)
    result = zeros(N + M)
    for m = 1:M
        for n = 1:N*2
            shifted_b = (n - m) < 0 || (n - m) > N - 1 ? 0 : b[n-m+1]
            toSum = a[m] * shifted_b
            result[n] += toSum
        end
    end
    result
end

function makeSinusoid(frequency, length, sampleRate, phase=0.0)
    n = 0:length-1
    cos.((2 * π * frequency / sampleRate .* n) .+ phase)
end

function flipHalves(x)
    N = length(x)
    N_2 = div(N, 2)
    [x[N_2+1:end]; x[1:N_2]]
end


function posNegSpec(x, ovr=4)
    xPadded = [x; zeros(length(x) * (ovr - 1))]
    spec = fft(flipHalves(xPadded))
    N = length(spec)
    N_2 = div(N, 2)

    y = flipHalves(spec)
    x = 2 * π * [-N_2+1:N_2] ./ N
    x, y
end

function posNegMagSpec(x)
    xPadded = [x; zeros(length(x) * 3)]
    magSpec = abs.(fft(flipHalves(xPadded)))
    N = length(magSpec)
    N_2 = div(N, 2)

    y = flipHalves(magSpec)
    x = 2 * π * [-N_2+1:N_2] ./ N
    x, y
end

function plotSpectrumZeroCenter!(x)
    x, y = posNegMagSpec(x)
    plot!(x, y, framestyle=:origin)
end

function plotSpectrumZeroCenter(x)
    x, y = posNegMagSpec(x)
    plot(x, y, framestyle=:origin, ylims=[0, 500])
end

# A zero padded magnitude spectrum
function plotMagSpec(x)
    xPadded = [x; zeros(length(x) * 3)]
    magSpec = abs.(fft(flipHalves(xPadded)))
    N = length(magSpec)
    N_2 = div(N, 2)

    x = 2 * π * [1:N_2] ./ N
    y = magSpec[1:N_2]
    plot!(x, y, framestyle=:origin)
end

function normalizePeak(x)
    x = x ./ maximum(abs.(x))
end

function plotSpectrum3D(signal, color=:blue)
    x, y = posNegSpec(signal, 1)
    y = normalizePeak(y)
    plotPhasor(y)
    plotComplexPlane3D(length(x))
end

function plotSpectrum3D!(signal, color=:blue)
    x, y = posNegSpec(signal, 1)
    y = normalizePeak(y)
    plotPhasor!(y, color)
    plotComplexPlane3D(length(x))
end


function halfBandFilter(x)
    s = fft(x)
    N_4 = div(length(s), 4)

    s[N_4+1:3*N_4] = zeros(2 * N_4)
    ifft(s)
end

function stemPlot(x)
    plot(x, title="a", ylims=(0, 1), line=:stem, marker=:circle, markersize=2)
end

function zTransformAtZ(signal::Array{Float64,1}, z::Complex{Float64}, startIndex=1)
    N = length(signal)
    result = 0 + 0im
    for n in 1:N
        # loop over all the subsequenct powers of z, multiplying with the signal
        result += signal[n] * z^(-(n - startIndex))
    end
    result
end

function zTransform(signal::Array{Float64,1}, range=-2:0.05:2, startIndex=1)
    # create a grid of z values to plot the transform over
    z = [Complex(x, y) for x in range, y in range]

    Xz = zTransformAtZ.(Ref(signal), z, startIndex)
    (Xz, z)
end

# Z-transform of an IIR filter
# a are the y components, starting at a1, b x components starting at b0
function zTransformIIRAtZ(a, b, z::Complex{Float64})
    N = length(b)
    M = length(a)
    numerator = 0 + 0im
    denominator = 1 + 0im
    for n in 1:N
        numerator += b[n] * z^(-(n - 1))
    end
    for m in 1:M
        denominator += a[m] * z^(-(m))
    end
    numerator / denominator
end


function zTransformIIR(a::Array{Float64,1}, b::Array{Float64,1}, range=-2:0.05:2)
    height = 5
    z = [Complex(y, x) for x in range, y in range]

    Xz = zTransformIIRAtZ.(Ref(a), Ref(b), z)

    mag = clamp.(abs.(Xz), 0, height)
    plot1 = Plots.plot(range, reverse(range), mag, st=:surface, camera=(30, 70), zlabel="mag", xlabel="real", ylabel="imag", legend=:none)

    omegas = 0:0.02:π

    # plot a line where the frequency response is (the unit circle)
    circX = cos.(omegas)
    circY = sin.(omegas)

    circZ = [zTransformIIRAtZ(a, b, circX[n] + circY[n] * 1im) for n in 1:length(circX)]

    Plots.plot!(plot1, circX, circY, abs.(circZ), color=:white)

    # left hand plot: plot magnitude response up to nyquist
    plot2 = Plots.plot(omegas, abs.(circZ), ylims=[-6, 6], label="magnitude")

    # plot phase response
    phase = angle.(circZ)
    Plots.plot!(plot2, omegas, phase, label="phase")

    # plot delay
    xstep = 1 / (length(omegas))
    Plots.plot!(plot2, omegas[1:end-1], (phase[1:end-1] .- phase[2:end]) ./ (pi * xstep), label="delay")

    Plots.plot(plot1, plot2, size=[1400, 600])
end

"DSP utilities are loaded"
