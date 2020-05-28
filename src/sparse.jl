@generated function value(
                   loss::MarginLoss,
                   target::AbstractSparseArray{Q,Ti,M},
                   output::AbstractArray{T,N}) where {T,N,Q,Ti,M}
    M > N && throw(ArgumentError("target has more dimensions than output; broadcasting not supported in this direction."))
    quote
      @nexprs $M (n)->@dimcheck(size(target,n) == size(output,n))
      out = similar(output)
      zeroQ = zero(Q)
      negQ = Q(-1)
      @simd for I in CartesianIndices(size(output))
          @nexprs $N n->(i_n = I[n])
          tgt = @nref($M,target,i)
          if tgt == zeroQ
              # convention is that zeros in a sparse array are interpreted as negative one
              @inbounds @nref($N,out,i) = value(loss, negQ, @nref($N,output,i))
          else
              @inbounds @nref($N,out,i) = value(loss, tgt, @nref($N,output,i))
          end
      end
      out
    end
end