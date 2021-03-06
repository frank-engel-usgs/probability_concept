function [obj] = fitProbabilityConcept(obj,varargin)



% Set up fittype and options.
ft = fittype( 'umax/M * log(1 + ((exp(M) - 1) * y)/(D - h) * exp(1 - y/(D - h)))', 'independent', 'y', 'dependent', 'u' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [1.0 0.0 0.0 0.0];  % Depth M h umax
opts.StartPoint = [1.0 0.1 0.0 0]; % Depth M h umax
opts.Upper = [1.0 8.0 Inf Inf]; % Depth M h umax

% Check that all data are valid
% fit>iFit X, Y and WEIGHTS cannot have NaN values.
is_ok = ~isnan(obj.zmedian) & ~isnan(obj.umedian);
obj.zmedian = obj.zmedian(is_ok);
obj.umedian = obj.umedian(is_ok);


ok_ = [1 1 1];
% Fit data
if length(ok_)>1
    % Fit model to data.
    [cf, gof, ~] = fit( obj.zmedian, obj.umedian, ft, opts );
    
    % Extract coefs and confidence intervals from fit
    cis = confint(cf);
    
    obj.M = cf.M; obj.M96ci = cis(:,2);
    obj.h_predicted = cf.h; obj.h95ci = cis(:,3);
    obj.umax = cf.umax; obj.umax95ci = cis(:,4);
    
    exponent95ci=confint(cf);
    obj.exponent95confint=exponent95ci;
    obj.PCrsqr=gof.rsquare;

    
    obj.u_pc = feval(cf,obj.z);
    obj.u_predict_int95 = predint(cf,obj.z,0.95);
end % if ok_



