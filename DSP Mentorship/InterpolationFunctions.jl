if !(isdefined(Base, :CircularArray))
    include("CircularArray.jl")
end

# see Niemitalo:
# http://yehar.com/blog/wp-content/uploads/2009/08/deip.pdf
#-------------------------------------------------------------------------------

# cutoff normalised to multiple of nyquist
function filterFFT(signal, cutoff)
    N_orig = length(signal)
    N_cutoff = convert(Integer, ceil(N_orig * cutoff / 2)) + 1

    s = fft(signal)

    # set everything above N_cutoff to zero
    for n in N_cutoff:(N_orig-N_cutoff+2)
        s[n] = 0.0 + 0.0im
    end
    result = CircularArray(real(ifft(s)))

    return result
end

#-------------------------------------------------------------------------------

# TODO If L is even, conjugacy implies X(L/2) = 0 - think about this!?
# function that makes x into length L by adding zeros in right place
function zeroPadFFT(fx, L::Integer)
    N_orig = length(fx)

    if iseven(N_orig)

        N_half = convert(Integer, N_orig / 2) # N_half is the one to the left of Nyquist
        numZeros = L - N_orig - 1
        fxRS = [fx[1]; fx[2:N_half]; fx[N_half+1] / 2; zeros(numZeros); conj(fx[N_half+1] / 2); fx[N_half+2:N_orig]]

    else # odd
        N_half = convert(Integer, ((N_orig + 1) / 2)) # N_half and N_half+1 is Nyquist
        numZeros = L - N_orig
        fxRS = [fx[1]; fx[2:N_half]; zeros(numZeros); fx[N_half+1:N_orig]]
    end

    return fxRS
end
#-------------------------------------------------------------------------------

# function that makes x into length L by removing high frequencies
function truncateFFT(fx, L::Integer)
    N_orig = length(fx)

    if iseven(L)

        N_half_new = convert(Integer, L / 2) # N_half will be the one to the left of Nyquist,
        # we need only one nyquist freq which is the sqrt of the hermitian product of two highest freqs
        # although, we could just throw it away. who cares about nyquist?
        # I care about nyquist because I have a test for it.
        newNyquist = 2 * sqrt(fx[N_half_new+1] * fx[N_half_new+1])

        fxRS = [fx[1]; fx[2:N_half_new]; newNyquist; fx[N_orig-N_half_new+2:N_orig]]

    else # odd result required
        N_half_new = convert(Integer, ((L + 1) / 2))
        fxRS = [fx[1]; fx[2:N_half_new]; fx[N_orig-N_half_new+2:N_orig]]
    end

    return fxRS
end


################################################################################

function idealFFTResample(sig, DSratio)
    # we cheat and resample to the closest integer length...
    # fft gives 0, 1, 2... N/2-1, N/2(if even), N/2-1*... 2*, 1*
    N_orig = length(sig)
    N_resample = convert(Integer, round(N_orig * DSratio))

    fx = fft(sig)

    if DSratio >= 1
        fxRS = zeroPadFFT(fx, N_resample)
    else
        fxRS = truncateFFT(fx, N_resample)

    end

    result = CircularArray(real(ifft(fxRS)))

    # TODO normalisation
    return DSratio * result
end

#-------------------------------------------------------------------------------
# Resample signal x by factor R, using an interpolation function f
function resample(x::CircularArray, R, f)
    L = convert(Integer, round(length(x) * R))
    x_i = CircularArray(zeros(L))

    for (i, v) in enumerate(x_i)
        sampPos = (i - 1) / R + 1
        sampInt = convert(Integer, floor(sampPos))
        sampFrac = sampPos - sampInt
        x_i[i] = f(x, sampInt, sampFrac)
    end
    return x_i
end

################################################################################
# Resampling functions

# nieve readout no anti-alias
# x - signal
# R - resample ratio


################################################################################
# Arguments for the single sample calculations:
# y is the wavetable
# i is the index in the wavetable just to the left of the interpolation interval
# x is how far thru the interpolation interval we are

function dropSample(y::CircularArray, i, x)
    return y[i]
end

#-------------------------------------------------------------------------------

function linearSample(y::CircularArray, i, x)
    return (1 - x) * y[i] + x * y[i+1]
end

#-------------------------------------------------------------------------------

# hermite interp 4 point 3rd order
function hermiteSampleFast(y::CircularArray, i, x)
    c0 = y[i]
    c1 = 1 / 2 * (y[i+1] - y[i-1])
    c2 = y[i-1] - 5 / 2 * y[i] + 2 * y[i+1] - 1 / 2 * y[i+2]
    c3 = 1 / 2 * (y[i+2] - y[i-1]) + 3 / 2 * (y[i] - y[i+1])
    return ((c3 * x + c2) * x + c1) * x + c0

end

#-------------------------------------------------------------------------------

# same as above but expanded
function hermiteSampleSlow(wt::CircularArray, sampInt, sampFrac)
    # get 4 samples
    p = Array(Real, 4)
    for n in 1:4
        m = mod(sampInt + n - 2, length(wt)) + 1
        p[n] = wt[m]
    end
    x = sampFrac
    return p[2] + 0.5 * x * (p[3] - p[1] + x * (2.0 * p[1] - 5.0 * p[2] + 4.0 * p[3] - p[4] + x * (3.0 * (p[2] - p[3]) + p[4] - p[1])))
end

#-------------------------------------------------------------------------------

function lagrangeSample(y::CircularArray, i, x)
    # 4-point, 3rd-order Lagrange (x-form)
    c0 = y[i]
    c1 = y[i+1] - 1 / 3.0 * y[i-1] - 1 / 2.0 * y[i] - 1 / 6.0 * y[i+2]
    c2 = 1 / 2.0 * (y[i-1] + y[i+1]) - y[i]
    c3 = 1 / 6.0 * (y[i+2] - y[i-1]) + 1 / 2.0 * (y[i] - y[i+1])
    return ((c3 * x + c2) * x + c1) * x + c0
end

#-------------------------------------------------------------------------------

function lagrangeSample65(y::CircularArray, i, x)
    ym1py1 = y[i-1] + y[i+1]
    twentyfourthym2py2 = 1 / 24.0 * (y[i-2] + y[i+2])
    c0 = y[i]
    c1 = 1 / 20.0 * y[i-2] - 1 / 2.0 * y[i-1] - 1 / 3.0 * y[i] + y[i+1] - 1 / 4.0 * y[i+2] + 1 / 30.0 * y[i+3]
    c2 = 2 / 3.0 * ym1py1 - 5 / 4.0 * y[i] - twentyfourthym2py2
    c3 = 5 / 12.0 * y[i] - 7 / 12.0 * y[i+1] + 7 / 24.0 * y[i+2] - 1 / 24.0 * (y[i-2] + y[i-1] + y[i+3])
    c4 = 1 / 4.0 * y[i] - 1 / 6.0 * ym1py1 + twentyfourthym2py2
    c5 = 1 / 120.0 * (y[i+3] - y[i-2]) + 1 / 24.0 * (y[i-1] - y[i+2]) + 1 / 12.0 * (y[i-1] - y[i])
    return ((((c5 * x + c4) * x + c3) * x + c2) * x + c1) * x + c0

end

#-------------------------------------------------------------------------------

function optimalSample(y::CircularArray, i, x)
    # Optimal for 4x oversampling (4-point, 2nd-order) (z-form)
    z = x - 1 / 2.0
    even1 = y[i+1] + y[i]
    odd1 = y[i+1] - y[i]
    even2 = y[i+2] + y[i-1]
    odd2 = y[i+2] - y[i-1]

    c0 = even1 * 0.38676264891201206 + even2 * 0.11324319172521946
    c1 = odd1 * 0.01720901456660906 + odd2 * 0.32839294317251788
    c2 = even1 * -0.228653995318581881 + even2 * 0.22858390767180370
    return (c2 * z + c1) * z + c0
end

#-------------------------------------------------------------------------------

# infinite-length sinc interpolation is "perfect reconstruction"
# windowing it makes it less perfect
# this one will be slow due to N cos, sin and divides per sample.
# filterFactor factor will filter the signal by stretching the
# sinc function by a factor of 1/filterFactor, lowering cutoff
function sincSample(wt::CircularArray, i, x, N=64, filterFactor=1)
    samplePos = i + x

    N2 = convert(Integer, N / 2)
    value = 0
    for j in (i-N2+1):(i+N2)
        syncTime = samplePos - j
        win = 0.5 * (cos(2 * π * syncTime / N) + 1)
        value += filterFactor * win * sinc(syncTime * filterFactor) * wt[j]
    end
    return value
end

#-------------------------------------------------------------------------------
function calcFilterFactor(noteHz, SR, tabLen)
    # how much should we filter out for this frequency
    # assuming fullband signal in table?
    # filterFactor > 1 means none
    origFreq = SR / tabLen
    return noteHz / origFreq
end

//

################################################################################

# interpolate by an integer multiple
function interpolateInteger(x::CircularArray, N, f)
    L = length(x)
    x_lp = CircularArray(zeros(L * N))

    for (i, v) in enumerate(x)
        j = N * (i - 1) + 1
        for n in 0:(N-1)
            x_lp[j+n] = f(x, i, n / N)
        end
    end
    return x_lp
end

#-------------------------------------------------------------------------------

# we need a non-integer ratio interpolation function
# DSratio must be > 1
#
function idealFFTUpsampleFrac(sig, DSratio)
    @show "DEPRECATED use idealFFTResample"
    N = length(sig)
    L = convert(Integer, round(N * DSratio))

    N_half = convert(Integer, floor(N / 2))
    fx = fft(sig)
    numZeros = L - N
    fxDs = [fx[1:N_half]; zeros(numZeros); fx[N-N_half:N]]
    return DSratio * real(ifft(fxDs))
end

#-------------------------------------------------------------------------------

# an ideal way to upsample a wavetable (offline only!) is to take the FFT, zero pad it, and then take the iFFT

function idealFFTUpsample(sig, DSratio::Integer)
    @show "DEPRECATED use idealFFTResample"
    N = length(sig)
    N_half = convert(Integer, floor(N / 2))
    fx = fft(sig)
    fxDs = [fx[1:N_half]; zeros((DSratio - 1) * N); fx[N-N_half:N]]
    return DSratio * real(ifft(fxDs))
end

#-------------------------------------------------------------------------------

function interpolateFrac(x::CircularArray, R, f, cleanFFTMode=true)
    L = convert(Integer, round(length(x) * R))
    x_i = CircularArray(zeros(L))

    if (cleanFFTMode)
        # adjust ratio to exacly fit 1 waveform in new sample buffer
        R = L / length(x)
    end

    for (i, v) in enumerate(x_i)
        sampPos = (i - 1) / R + 1
        sampInt = convert(Integer, floor(sampPos))
        sampFrac = sampPos - sampInt
        x_i[i] = f(x, sampInt, sampFrac)
    end
    return x_i
end

#-------------------------------------------------------------------------------

function interpolateFracSG(x::CircularArray, R, f, cleanFFTMode=true)
    L = convert(Integer, round(length(x) * R))
    x_i = CircularArray(zeros(L))

    if (cleanFFTMode)
        # adjust ratio to exacly fit 1 waveform in new sample buffer
        R = L / length(x)
    end

    for (i, v) in enumerate(x_i)
        sampPos = (i - 1) / R + 1
        sampInt = convert(Integer, floor(sampPos))
        sampFrac = sampPos - sampInt
        x_i[i] = f(x, sampInt, sampFrac, R)
    end
    return x_i
end

# wavetable read func

#-------------------------------------------------------------------------------
# read out wavetable at certain pitch with interpolation function
# x - wavetable
# pHz the note frequency
# f the interpolation function
# SR the output sample rate
# lenght - output length in seconds

# returns an array (not circular)
function outputWavetable(x::CircularArray, pHz, SR, len, f, window=false)
    L = convert(Integer, round(len * SR))
    out = zeros(L)
    phaseInc = pHz / SR # cycles per sample
    for i in 1:L
        samplePos = (i - 1) * phaseInc * length(x)
        samplePos = mod(samplePos, length(x))
        sampInt = convert(Integer, floor(samplePos))
        sampFrac = samplePos - sampInt
        # add one because of julias 1 indexing
        s = f(x, sampInt + 1, sampFrac)
        out[i] = s
    end
    return out
end

# same as above but takes a phasor waveform for frequency modulation
function outputWavetableWithPhasor(x::CircularArray, phasor, SR, len, f, window=false)
    L = convert(Integer, round(len * SR))
    out = zeros(L)
    for i in 1:L
        samplePos = phasor[i] * length(x)
        sampInt = convert(Integer, floor(samplePos))
        sampFrac = samplePos - sampInt
        # add one because of julia's 1 indexing
        s = f(x, sampInt + 1, sampFrac)
        out[i] = s
    end
    return CircularArray(out)
end

# same as above but takes a phase increment array similar to our C++ tick func
function outputWavetableWithPhaseIncs(x::CircularArray, phaseIncs::CircularArray, SR, len, f, window=false)
    L = convert(Integer, round(len * SR))
    out = zeros(L)
    phaseAccum = 0.0
    for i in 1:L
        phaseAccum += phaseIncs[i]
        samplePos = phaseAccum * length(x)
        sampInt = convert(Integer, floor(samplePos))
        sampFrac = samplePos - sampInt
        # add one because of julia's 1 indexing
        s = f(x, sampInt + 1, sampFrac)
        out[i] = s
    end
    return CircularArray(out)
end


################################################################################
# UNIT TESTS
# TODO use Julia's native test frmework!
################################################################################
#=
using FactCheck

facts("Test: zero pad FFT") do
    t_data = CircularArray([1.0, 2.0, 3.0, 3.0, 2.0])
    expect = CircularArray([1.0, 2.0, 3.0, 0.0, 0.0, 3.0, 2.0])
    result = zeroPadFFT(t_data, length(expect))


    for i in 1:length(expect)
        @fact result[i] --> expect[i] "A sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 2.0, 3.0im, 2.0])
    expect = CircularArray([1.0, 2.0, 1.5im, -1.5im, 2.0])
    result = zeroPadFFT(t_data, length(expect))

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "B sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 2.0, 3.0, 2.0])
    expect = CircularArray([1.0, 2.0, 1.5, 0.0, 0.0, 1.5, 2.0])
    result = zeroPadFFT(t_data, length(expect))

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "C sample mismatch at i=$i"
    end
end


facts("Test: truncate FFT") do
    t_data = CircularArray([1.0, 2.0, 9.0, 9.0, 2.0])
    expect = CircularArray([1.0, 2.0, 18.0, 2.0])
    result = truncateFFT(t_data, 4)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "A sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 2.0, 0.0, 1.0, 0.0, 2.0])
    expect = CircularArray([1.0, 2.0, 0.0, 0.0, 2.0])
    result = truncateFFT(t_data, 5)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "B sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 2.0, 2.0])
    expect = CircularArray([1.0, 4.0])
    result = truncateFFT(t_data, 2)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "C sample mismatch at i=$i"
    end
end

facts("Test: FFT trancations and padding inverse round trip") do
    t_data = CircularArray([1.0, 2.0, 0.0, 2.0])
    expect = CircularArray([1.0, 2.0, 0.0, 2.0])

    result = truncateFFT(zeroPadFFT(t_data, 5), length(expect))

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "A sample mismatch at i=$i"
    end

    result = truncateFFT(zeroPadFFT(t_data, 25), length(expect))

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "B sample mismatch at i=$i"
    end

    # go the other way - this only works for zeroed signals
    t_data = CircularArray([1.0, 0.0, 0.0, 0.0])
    expect = CircularArray([1.0, 0.0, 0.0, 0.0])

    shorter = truncateFFT(t_data, 2)
    result = zeroPadFFT(shorter, length(expect))

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "C sample mismatch at i=$i"
    end
end


# Test the interpolation functions
facts("Test: FFT Resample") do
    t_data = CircularArray([1.0, 1.0])
    expect = CircularArray([1.0, 1.0, 1.0, 1.0])
    result = idealFFTResample(t_data, 2)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "A sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 1.0])
    expect = CircularArray([1.0, 1.0, 1.0])
    result = idealFFTResample(t_data, 3)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "B sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 0.0, -1.0, 0.0])
    expect = CircularArray([1.0, -1.0])
    result = idealFFTResample(t_data, 0.5)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "C sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0, 0.0])
    expect = CircularArray([1.0, -1.0, 1.0, -1.0])
    result = idealFFTResample(t_data, 0.5)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "D sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 0.0, 0.0, 0.0])
    expect = CircularArray([0.75, -0.25]) # TODO does this make sense?
    result = idealFFTResample(t_data, 0.5)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "E sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, -1.0]) # TODO does this make sense?
    expect = CircularArray([1.0, 0.0, -1.0, 0.0])
    result = idealFFTResample(t_data, 2)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "F sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, -1.0]) # TODO does this make sense?
    expect = CircularArray([1.0, 0.0, -1.0, 0.0])
    result = idealFFTResample(t_data, 2)

    for i in 1:length(expect)
        @fact result[i] --> expect[i] "G sample mismatch at i=$i"
    end
end

#
facts("Test: FFT Resample round trip") do

    # stretch and compress
    t_data = CircularArray([1.0, 0.0, -1.0, 0.0])
    expect = t_data
    result = idealFFTResample(t_data, 4)
    result = idealFFTResample(result, 0.25)

    for i in 1:length(expect)
        @fact result[i] --> roughly(expect[i], atol=1.0e-16) "A sample mismatch at i=$i"
    end

    t_data = CircularArray([1.0, 0.0, 0.0, 0.0])
    expect = t_data
    result1 = idealFFTResample(t_data, 4)
    result = idealFFTResample(result1, 0.25)

    for i in 1:length(expect)
        @fact result[i] --> roughly(expect[i], atol=1.0e-16) "B sample mismatch at i=$i"
    end

    # compress and strecth (needs lowpassed input)
    t_data = CircularArray([1.0, 0.0, -1.0, 0.0])
    expect = t_data
    result = idealFFTResample(t_data, 0.5)
    result = idealFFTResample(result, 2)

    for i in 1:length(expect)
        @fact result[i] --> roughly(expect[i], atol=1.0e-16) "C sample mismatch at i=$i"
    end
end

################################################################################
# Test the interpolation functions
################################################################################
facts("Test: Drop Sample") do
    x = CircularArray([1.0, 1.0])
    e = CircularArray([1.0, 1.0, 1.0, 1.0])
    r = interpolateInteger(x, 2, dropSample)

    for i in 1:4
        @fact r[i] --> e[i] "sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 0.0])
    e = CircularArray([1.0, 1.0, 0.0, 0.0])
    r = interpolateInteger(x, 2, dropSample)

    for i in 1:4
        @fact r[i] --> e[i] "sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 1.0])
    e = CircularArray([1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
    r = interpolateInteger(x, 3, dropSample)

    for i in 1:6
        @fact r[i] --> e[i] "sample mismatch at i=$i"
    end
end

facts("Test: Linear Interpolate") do
    x = CircularArray([1.0, 0.0])
    e = CircularArray([1.0, 0.5, 0.0, 0.5])
    r = interpolateInteger(x, 2, linearSample)

    for i in 1:4
        @fact r[i] --> e[i] "sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 1.0])
    e = CircularArray([1.0, 1.0, 1.0, 1.0])
    r = interpolateInteger(x, 2, linearSample)

    for i in 1:4
        @fact r[i] --> e[i] "sample mismatch at i=$i"
    end

    x = CircularArray([3.0, 0.0])
    e = CircularArray([3.0, 2.0, 1.0, 0.0, 1.0, 2.0])
    r = interpolateInteger(x, 3, linearSample)

    for i in 1:6
        @fact r[i] --> e[i] "sample mismatch at i=$i"
    end
end

facts("Test: Hermite Interpolate") do

    x = CircularArray([1.0, 1.0])
    e = CircularArray([1.0, 1.0, 1.0, 1.0])
    r = interpolateInteger(x, 2, hermiteSampleFast)

    for i in 1:4
        @fact r[i] --> e[i] "A sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 0.0])
    e = CircularArray([1.0, 0.5, 0.0, 0.5])
    r = interpolateInteger(x, 2, hermiteSampleFast)

    for i in 1:4
        @fact r[i] --> e[i] "B sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 0.0])
    e = CircularArray([1.0, 0.84375, 0.5, 0.15625, 0.0, 0.15625, 0.5, 0.84375])
    r = interpolateInteger(x, 4, hermiteSampleFast)

    for i in 1:8
        @fact r[i] --> e[i] "C sample mismatch at i=$i"
    end

end

facts("Test: Cubic Lagrange Interpolate") do

    x = CircularArray([1.0, 1.0])
    e = CircularArray([1.0, 1.0, 1.0, 1.0])
    r = interpolateInteger(x, 2, lagrangeSample)

    for i in 1:4
        @fact r[i] --> e[i] "A sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 0.0])
    e = CircularArray([1.0, 0.5, 0.0, 0.5])
    r = interpolateInteger(x, 2, lagrangeSample)

    for i in 1:4
        @fact r[i] --> e[i] "B sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 0.0])
    e = CircularArray([1.0, 0.78125, 0.5, 0.2187500000000001, 0.0, 0.21875000000000003, 0.5, 0.78125])
    r = interpolateInteger(x, 4, lagrangeSample)

    for i in 1:8
        @fact r[i] --> e[i] "C sample mismatch at i=$i"
    end

end

facts("Test: Sinc Interpolate") do

    x = CircularArray([1.0, 1.0])
    e = CircularArray([1.0, 1.0, 1.0, 1.0])
    r = interpolateInteger(x, 2, sincSample)

    for i in 1:4
        @fact r[i] --> roughly(e[i], atol=1.0e-4) "A sample mismatch at i=$i"
    end

    x = CircularArray([1.0, 0.0])
    e = CircularArray([1.0, 0.5, 0.0, 0.5])
    r = interpolateInteger(x, 2, sincSample)

    for i in 1:4
        @fact r[i] --> roughly(e[i], atol=1.0e-4) "B sample mismatch at i=$i"
    end

end

# facts("Test: Smith-Gosset Interpolate") do
#
#     x = CircularArray([1.0,1.0]);
#     e = CircularArray([1.0,1.0,1.0,1.0]);
#     r = interpolateInteger(x, 2, smithGossetSample);
#
#     for i in 1:4
#         @fact r[i] --> roughly(e[i], atol=1.0e-3) "A sample mismatch at i=$i"
#     end
#
#     x = CircularArray([1.0,0.0]);
#     e = CircularArray([1.0,0.5,0.0,0.5]);
#     r = interpolateInteger(x, 2, smithGossetSample);
#
#     for i in 1:4
#         @fact r[i] --> roughly(e[i], atol=1.0e-3) "B sample mismatch at i=$i"
#     end
#
# end
=#