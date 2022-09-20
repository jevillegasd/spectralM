function [peakAnalysis] = resonanceAnalysis(data,pks,lambda0,param)
%Extract ring resonator parameeters from power measuremnt data in dBm
%Juan Esteban Villegas, Masdar Institute, 2018
%Modified to fit the variable types in Spectral Measurements
% Inputs:
%     param
%         param(1) = L[double]: Resonator/interferometer distance in nm
%         param(2) = n_g[double]: Group index
%         param(3) = windowSc [double]: Window within wich make the lorentizain fit
% Outputs
%     peakAnalysis
%         nop = npeaks;
%         wav[] = lambda0;
%         fsr[] = FSR;
%         fwhm[] = FWHM;
%         q[] = Q;
%         ng[] = ng;
%         a[] =alpha;
%         alphadB[] =alphadB;     

    if(pks(1)<mean(data(:,2))) % Negative Peaks
        data(:,2) = -data(:,2);
        pks = -pks;
    end
    L = param(1)*1e-9; n_g = param(2); windowSc = param(3);    
    npeaks = length(lambda0); %Number of peaks
    peakAnalysis.nop = npeaks;
    peakAnalysis.pks = pks; peakAnalysis.wav = lambda0;
    
    FSR = zeros(1,npeaks);
    Q = FSR; FWHM = FSR; ng = FSR; alpha = FSR; alphadB = FSR;   
    D = data; E = D(:,2); x = D(:,1);
    
    if ~isempty(lambda0)
        %% Measurement of FSR for all the data
        if npeaks>1
            FSR =  diff(lambda0);   % Free spectral range (distance between peaks.   
            FSR(end+1)=FSR(end); %appending FSR's last element to itself
        else
            FSR = lambda0^2/(n_g*L);
        end
        
        %% Analysis of the resonance for all found peaks
        for i = 1:npeaks
            %Extract the region around the interested resonance
            dlambda = FSR(i)*windowSc;
            minx = lambda0(i) - dlambda/2;  maxx = lambda0(i) + dlambda/2; 
            
            clear E2 x2
            x2 = x(x>minx & x<maxx);
            E2 = E(x>minx & x <maxx);

            %% Measure the FWHM at the resonance
            try
                [FWHM(i),~] = getFWHM([x2,E2],FSR(i));
            catch Em
                FWHM(i) = nan;
            end
%             figure(1); hold on; plot(data(:,1),data(:,2));
%             plot(fwhm_line(1,:),fwhm_line(2,:)); hold off
            
            %% Compute resonator parameters
            Q(i) = lambda0(i)/FWHM(i);
            ng(i)= lambda0(i)^2/(L*FSR(i));
            alpha(i) = 2*pi*ng(i)/lambda0(i)^2*FWHM(i)*1e9; %power fraction per m
            alphadB(i) = 0.1*alpha(i)/log(10); 
        end

        %Fill output variables
        peakAnalysis.fsr = FSR;
        peakAnalysis.fwhm = FWHM;
        peakAnalysis.q = Q;
        peakAnalysis.ng = ng;
        peakAnalysis.a =alpha;
        peakAnalysis.adB =alphadB;
    else
        peakAnalysis = {};
        peakAnalysis.wav = [];
        peakAnalysis.fsr = [];
        peakAnalysis.fwhm = [];
        peakAnalysis.q = [];
        peakAnalysis.ng = [];
        peakAnalysis.a =[];
    end
end

function[fwhm, fwhm_line]=getFWHM(data,FSR)
    %Find FWHM for raw power data measurements in dBm of one resonance peak
    %Data must be centered in the interested resonance
    %Juan Esteban Villegas, Masdar Institute, 2018
    %Update JVillegas 2021
    
    %First check that the version of matlab includes curve fitting toolbox
    v = ver;
    has_fsolve = any(strcmp(cellstr(char(v.Name)), 'Curve Fitting Toolbox'));
    if ~has_fsolve
        warning('The resonance analysis works only with the Curve Fitting toolbox.');
        
        fwhm = 0;
        fwhm_line = 0;
    else
        x = data(:,1); y = data(:,2);   
        ind = round(length(x)/2); cp = x(ind); %Central peak info

        %% Change axis of data and center around the resonance
        my = min(y);
        ny(:,1) = x-cp;
        ny(:,2) = (y-my);
        maxny = ny(ind,2);  
        %% Fit the data to the expected power function of the resonator
        %  this is a lorenzian-cauchy distribution

        equ =  sprintf('I/(1+(4*a/(1-a)^2)*(sin(phi/2+ps)^2))');  
        %ps is a small phase shift given that the maximum value could not
        %correspond to the actual resonance in the ring due to noise
        up = [maxny+20, 1, pi/20]; low = [maxny, 0,-pi/20]; start = [maxny+10, 0.99, 0];
        %Fit the data to the lorenzian-cauchy distribution  
        myfittype = fittype(equ,'independent',{'phi'});  
        opts = fitoptions( 'Method', 'NonlinearLeastSquares','Upper',up,'Lower',low,'StartPoint',start );
        phi = 2*pi/FSR*ny(:,1);         %Phase shift
        myfit1 = fit(phi,ny(:,2),myfittype,opts);
        a = myfit1.a; fitmax = myfit1.I;

        newy1 = fitmax./(1+(4*a/(1-a)^2).*(sin(phi/2)).^2);
         %% Get the FWHM of the fitted function plot
         x2 = x(x>cp-FSR/2&x<cp+FSR/2); y2 = newy1(x>cp-FSR/2&x<cp+FSR/2); %Measure FWHM only in the max peak (if more than one)
         [fwhm, sp] = find_fwhm([x2 y2]);     
         fwhm_line = [sp; fitmax-3+my fitmax-3+my];
       %  plot(sp,[fitmax-3+my fitmax-3+my],'marker','o');
    end
end

function[fwhm, sp]=find_fwhm(data)
    %Find FWHM for noize free diferentiable data in dBm
    %Juan Esteban Villegas, Masdar Institute, 2018
    %Based on code by Ebo Ewusi-Annan / University of Florida/August 2012
    x = data(:,1); y = data(:,2);
    
    %% Spline approximation method
    y_lin = 10.^(y./10); %Data from dB to power fraction
    [maxy, cen_i] = max(y_lin);  
    y1= y_lin./maxy; 
    ydata(:,1) = y1; ydata(:,2) = x;
    lh = ydata(1:cen_i,:);
    rh = ydata(cen_i:length(x),:);
    sp1 = spline(lh(:,1),lh(:,2), 0.5); %fit a transversal spline to a value of -3dB the maximum
    sp2 = spline(rh(:,1),rh(:,2), 0.5); %fit a spline to a value of -3dB the maximum
    sp = [sp1 sp2];
    fwhm = diff(sp);
 end
