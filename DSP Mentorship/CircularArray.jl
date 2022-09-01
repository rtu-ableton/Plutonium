struct CircularArray{T} <: AbstractVector{T}
    data::Vector{T}
end

# Constructor that creates a CircularArray of length N
function CircularArray(N::Integer)
    x = Array{Any,N}
    return CircularArray(x)
end

# TODO promote things like integers when setting
function Base.setindex!(X::CircularArray{T}, v::T, i::Integer) where {T}
    X.data[mod(i - 1, length(X.data))+1] = v
end

function Base.getindex(X::CircularArray{T}, i::Integer) where {T}
    return X.data[mod(i - 1, length(X.data))+1]
end

function Base.length(X::CircularArray{T}) where {T}
    return Base.length(X.data)
end

function Base.size(X::CircularArray{T}) where {T}
    return Base.size(X.data)
end

# function Base.endof{T,N}(X::CircularArray{T,N})
#     return endof(X.data)
# end

# convert(::Type{CircularArray{ParticleBreakpoint,1}}, ::Array{ParticleBreakpoint,1})
