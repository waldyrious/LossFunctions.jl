
# ==========================================================================
# L(y, t) = |y - t|^P

immutable LPDistLoss{P} <: DistanceBasedLoss
  LPDistLoss() = typeof(P) <: Real ? new() : error()
end

LPDistLoss(p::Real) = LPDistLoss{p}()

value{P}(l::LPDistLoss{P}, r::Real) = abs(r)^P
function deriv{P}(l::LPDistLoss{P}, r::Real)
  if r == 0
    zero(r)
  elseif r >= 0
    P * r^(P-1)
  else
    -P * abs(r)^(P-1)
  end
end
function deriv2{P}(l::LPDistLoss{P}, r::Real)
  if r == 0
    zero(r)
  elseif r >= 0
    P * (P-1) * r^(P-2)
  else
    -P * (P-1) * abs(r)^(P-2)
  end
end
value_deriv{P}(l::LPDistLoss{P}, r::Real) = (value(l,r), deriv(l,r))

issymmetric{P}(::LPDistLoss{P}) = true
isdifferentiable{P}(::LPDistLoss{P}) = P > 1
isdifferentiable{P}(::LPDistLoss{P}, at) = P > 1 || at != 0
islipschitzcont{P}(::LPDistLoss{P}) = P == 1
isconvex{P}(::LPDistLoss{P}) = P >= 1

# ==========================================================================
# L(y, t) = |y - t|

typealias L1DistLoss LPDistLoss{1}

value(l::L1DistLoss, r::Real) = abs(r)
deriv(l::L1DistLoss, r::Real) = sign(r)
deriv2(l::L1DistLoss, r::Real) = zero(r)
value_deriv(l::L1DistLoss, r::Real) = (abs(r), sign(r))

isdifferentiable(::L1DistLoss) = false
isdifferentiable(::L1DistLoss, at) = at != 0
islipschitzcont(::L1DistLoss) = true
isconvex(::L1DistLoss) = true

# ==========================================================================
# L(y, t) = (y - t)^2

typealias L2DistLoss LPDistLoss{2}

value(l::L2DistLoss, r::Real) = abs2(r)
deriv(l::L2DistLoss, r::Real) = 2r
deriv2(l::L2DistLoss, r::Real) = 2
value_deriv(l::L2DistLoss, r::Real) = (abs2(r), 2r)

isdifferentiable(::L2DistLoss) = true
isdifferentiable(::L2DistLoss, at) = true
islipschitzcont(::L2DistLoss) = false
isconvex(::L2DistLoss) = true

# ==========================================================================
# L(y, t) = max(0, |y - t| - ɛ)

immutable EpsilonInsLoss <: DistanceBasedLoss
  eps::Float64

  function EpsilonInsLoss(ɛ::Real)
    ɛ > 0 || error("ɛ must be strictly positive")
    new(convert(Float64, ɛ))
  end
end

value{T<:Real}(l::EpsilonInsLoss, r::T) = max(zero(T), abs(r) - l.eps)
deriv{T<:Real}(l::EpsilonInsLoss, r::T) = abs(r) <= l.eps ? zero(T) : sign(r)
deriv2{T<:Real}(l::EpsilonInsLoss, r::T) = zero(T)
function value_deriv{T<:Real}(l::EpsilonInsLoss, r::T)
  absr = abs(r)
  absr <= l.eps ? (zero(T), zero(T)) : (absr - l.eps, sign(r))
end

# ==========================================================================
# L(y, t) = -ln(4 * exp(y - t) / (1 + exp(y - t))²)

immutable LogitDistLoss <: DistanceBasedLoss end

function value(l::LogitDistLoss, r::Real)
  er = exp(r)
  -log(4 * er / abs2(1 + er))
end

function deriv(l::LogitDistLoss, r::Real)
  tanh(r / 2)
end

function deriv2(l::LogitDistLoss, r::Real)
  er = exp(r)
  2*er / abs2(1 + er)
end

function value_deriv(l::LogitDistLoss, r::Real)
  er = exp(r)
  er1 = 1 + er
  -log(4 * er / abs2(er1)), (er - 1) / (er1)
end

