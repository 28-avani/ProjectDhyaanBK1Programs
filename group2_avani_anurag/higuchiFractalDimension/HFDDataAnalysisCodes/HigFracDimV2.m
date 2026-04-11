function [HFD,rmse,kmaxFinal,minuslnK,lnL] = HigFracDimV2(data, kmax, maxRmse,fastFlag,optimiseRmseFlag,plotFlag)
if ~exist('kmax','var');                kmax=8;                     end
if ~exist('maxRmse','var');             maxRmse = 0.05;             end
if ~exist('fastFlag','var');            fastFlag = 0;               end
if ~exist("optimiseRmseFlag",'var');    optimiseRmseFlag = 1;       end
if ~exist('plotFlag','var');            plotFlag = 0;               end

N = length(data);
L = zeros(1,kmax); x = zeros(1,kmax); y = zeros(1,kmax);

for k = 1:kmax
    for m = 1:k
        norm_factor = (N-1)/(round((N-m)/k)*k); 
        X = sum(abs(diff(data(m:k:N)))); 
        L(m)=X*norm_factor/k; 
    end
    y(k)=log(sum(L)/k); 
    x(k)=log(1/k); 
end

if fastFlag
    D = polyfit(x,y,1);
    HFD = D(1);
    kmaxFinal = kmax;
    rmse = nan;
    minuslnK = x; lnL = y;
else
    [D,E] = fit(x',y','poly1'); 
    HFD = D.p1;
    rmse = E.rmse;
    kmaxFinal = kmax;
    minuslnK = x; lnL = y;
end
end