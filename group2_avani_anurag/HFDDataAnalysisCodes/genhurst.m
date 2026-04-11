function H = genhurst(S,q,maxT)
if ~exist('q','var'); q=1; end
if ~exist('maxT','var'); maxT=19; end
L = length(S);
lq = length(q);
H = [];
for Tmax=5:maxT
    x = 1:Tmax;
    mcord = zeros(Tmax,lq);
    for tt = 1:Tmax
        dV = S((tt+1):tt:L) - S(((tt+1):tt:L)-tt);
        mcord(tt,:) = mean(abs(dV).^q);
    end
    for i=1:lq
        p = polyfit(log(x),log(mcord(:,i)'),1);
        H(i) = p(1)/q(i);
    end
end
end