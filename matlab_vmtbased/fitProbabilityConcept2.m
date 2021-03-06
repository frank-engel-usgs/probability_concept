function [obj] = fitProbabilityConcept2(obj,varargin)



% Set up fittype and options.
ft = fittype( 'umax/M * log(1 + ((exp(M) - 1) * y) / D * exp(1 - y/D))', 'independent', 'y', 'dependent', 'u' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [1.0 0.0 0.0];  % Depth M h umax
opts.StartPoint = [1.0 0.1 0]; % Depth M h umax
opts.Upper = [1.0 8.0 Inf]; % Depth M h umax



ok_ = [1 1 1];
% Fit data
if length(ok_)>1
    % Fit model to data.
    [cf, gof, ~] = fit( obj.zmedian, obj.umedian, ft, opts );
    
    % Extract coefs and confidence intervals from fit
    cis = confint(cf);
    
    obj.M = cf.M; obj.M96ci = cis(:,2);
    obj.umax = cf.umax; obj.umax95ci = cis(:,3);
    
    exponent95ci=confint(cf);
    obj.exponent95confint=exponent95ci;
    obj.PCrsqr=gof.rsquare;

    
    obj.u_pc = feval(cf,obj.z);
    obj.u_predict_int95 = predint(cf,obj.z,0.95);
end % if ok_



