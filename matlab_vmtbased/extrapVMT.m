function [extrap] = extrapVMT(udim,zdim,range,fitcombo,method,varargin)


zedges = 0.1:0.05:1;
z = zdim(:); u = udim(:);
zbin = discretize(z,zedges);
[~,~,zix] = unique(zbin) ;
avgz = accumarray(zix,z,[],@nanmean) ;
y    = accumarray(zix,u,[],@nanmean) ;
unit25 = accumarray(zix,u,[],@(x) prctile(x,25)) ;
unit75 = accumarray(zix,u,[],@(x) prctile(x,75)) ;
unitmed = accumarray(zix,u,[],@nanmedian) ;

[avgz,ind]=sort(avgz,'descend');
y=y(ind); unit25=unit25(ind); unit75=unit75(ind); unitmed=unitmed(ind);
idxz = find(~isnan(avgz));

obj.umedian = y(idxz);
obj.zmedian = avgz(idxz);
obj.unit25 = unit25;
obj.unit75 = unit75;


% Initialize fit boundaries
lowerbnd=[-Inf 0.01];
upperbnd=[Inf   1];


% If less than 6 cells, use default P/P 1/6, otherwise optimize the fit

switch fitcombo
    case ('PowerPower')
        obj.z=0:0.01:1;
        obj.z=obj.z';
        zc=nan;
        uc=nan;
        idxpower = idxz;
    case ('ConstantPower')
        obj.z=0:0.01:max(avgz(idxz));
        obj.z=[obj.z' ; nan];
        zc=max(avgz(idxz))+0.01:0.01:1;
        zc=zc';
        uc=repmat(y(idxz(1)),size(zc));
        idxpower = idxz;
        
    case ('3-PointPower')
        obj.z=0:0.01:max(avgz(idxz));
        obj.z=[obj.z' ; nan];
        % If less than 6 bins use constant at the top
        if length(idxz)<6
            zc=max(avgz(idxz))+0.01:0.01:1;
            zc=zc';
            uc=repmat(y(idxz(1)),size(zc));
        else
            p=polyfit(avgz(idxz(1:3)),y(idxz(1:3)),1);
            zc=max(avgz(idxz))+0.01:0.01:1;
            zc=zc';
            uc=zc.*p(1)+p(2);
        end % if nbins
        
    case ('ConstantNo Slip')
        
        % Optimize Constant / No Slip if sufficient cells
        % are available.
        if strcmpi(method,'optimize')
            idx=idxz(1+end-floor(length(avgz(idxz))/3):end);
            if length(idx)<3
                method='default';
            end % if
            
            % Compute Constant / No Slip using WinRiver II and
            % RiverSurveyor Live default cells
        else
            idx=find(avgz(idxz)<=0.2);
            if isempty(idx)
                idx=idxz(end);
            else
                idx=idxz(idx);
            end
        end % if method
        
        % Configure u and z arrays
        idxns=idx;
        obj.z=0:0.01:avgz(idxns(1));
        obj.z=[obj.z' ; nan];
        idxpower=idx;
        zc=max(avgz(idxz))+0.01:0.01:1;
        zc=zc';
        uc=repmat(y(idxz(1)),size(zc));
        
    case '3-PointNoSlip'
        
        % Optimize Constant / No Slip if sufficient cells
        % are available.
        if strcmpi(method,'optimize')
            idx=idxz(1+end-floor(length(avgz(idxz))/3):end);
            if length(idx)<4
                method='default';
            end % if
            
            % Compute Constant / No Slip using WinRiver II and
            % RiverSurveyor Live default cells
        else
            idx=find(avgz(idxz)<=0.2);
            if isempty(idx)
                idx=idxz(end);
            else
                idx=idxz(idx);
            end
        end % if method
        
        % Configure u and z arrays
        idxns=idx;
        obj.z=0:0.01:avgz(idxns(1));
        obj.z=[obj.z' ; nan];
        idxpower=idx;
        
        % If less than 6 bins use constant at the top
        if length(idxz)<6
            zc=max(avgz(idxz))+0.01:0.01:1;
            zc=zc';
            uc=repmat(y(idxz(1)),size(zc));
        else
            p=polyfit(avgz(idxz(1:3)),y(idxz(1:3)),1);
            zc=max(avgz(idxz))+0.01:0.01:1;
            zc=zc';
            uc=zc.*p(1)+p(2);
        end % if nbins
        
end % switch fitcombo
%% Compute exponent
zfit=avgz(idxpower);
yfit=y(idxpower);

% Check data validity
ok_ = isfinite(zfit) & isfinite(yfit);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end % if

obj.exponent=nan;
obj.exponent95confint=[nan nan];
obj.rsqr=nan;

switch lower(method)
    case ('manual')
        obj.exponent=varargin{1};
        model=['x.^' num2str(obj.exponent)];
        ft_=fittype({model},'coefficients',{'a1'});
        fo_ = fitoptions('method','LinearLeastSquares');
    case ('default')
        obj.exponent=1./6;
        model=['x.^' num2str(obj.exponent)];
        ft_=fittype({model},'coefficients',{'a1'});
        fo_ = fitoptions('method','LinearLeastSquares');
    case ('optimize')
        
        % Set fit options
        fo_ = fitoptions('method','NonlinearLeastSquares','Lower',lowerbnd,'Upper',upperbnd);
        ft_ = fittype('power1');
        
        % Set fit data
        strt=yfit(ok_);
        st_ = [strt(end) 1./6 ];
        set(fo_,'Startpoint',st_);
end % switch method

% Fit data
if length(ok_)>1
    [cf, gof, ~] = fit(zfit(ok_),yfit(ok_),ft_,fo_);
    
    % Extract exponent and confidence intervals from fit
    if strcmpi(method,'optimize')
        obj.exponent=cf.b;
        if obj.exponent<0.05
            obj.exponent=0.05;
        end %  if exponent
    end % if method
    
    if length(zfit(ok_))>2
        exponent95ci=confint(cf);
        if strcmpi(method,'optimize')
            exponent95ci=exponent95ci(:,2);
        end % if
        obj.exponent95confint=exponent95ci;
        obj.rsqr=gof.rsquare;
    else
        exponent95ci=nan;
        exponent95ci=nan;
        obj.exponent95confint=nan;
        obj.rsqr=nan;
    end % if confint
end % if ok_

% Compute alpha (k) based on the exponent from the power law approximation
k = 1/(obj.exponent + 1);
obj.k = k;

% Fit power curve to appropriate data
obj.coef=((obj.exponent+1).*0.05.*nansum(y(idxpower)))./...
    nansum(((avgz(idxpower)+0.5.*0.05).^(obj.exponent+1))-((avgz(idxpower)-0.5.*0.05).^(obj.exponent+1)));

% Compute residuals
obj.residuals=y(idxpower)-obj.coef.*avgz(idxpower).^(obj.exponent);

% Compute values (velocity or discharge) based on exponent and compute
% coefficient
obj.u=obj.coef.*obj.z.^(obj.exponent);
if ~isnan(zc)
    obj.u=[obj.u ; uc];
    obj.z=[obj.z ; zc];
end % if zc
obj.validData = idxz;

%% Compute the probability concept alternative velocity distribution
% This fit is computed from the dimensionaless median values used in the
% standard extrap approach
[obj] = fitProbabilityConcept(obj);

extrap = obj;
