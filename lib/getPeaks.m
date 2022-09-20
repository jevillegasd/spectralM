function [pks,lambda]=getPeaks(data,filterStat,filterParam)
%Function to find the peaks of a spectrum using multiple options of filters,
%namely: MinPeakHeight, MinPeakProminence, MaxPeakWidth, MinPeakWidth
%and MinPeakDistance.
%Part of Spectral Measurements
%Copyright (C) NYU 2019
%Developped by Juan Villegas
    if nargin ~= 3, return; end
    if isempty (data)    
     return         
    end
    pks = []; lambda= [];
    E = data(:,2);
    x = data(:,1);

    [m] = size(x,1); %units
    R = 1e9 * (x(m)-x(1)); %Range of the measurement in nm
    Distunit = R/m; %nm/units (step size)

    nullHeight = -120;
    nullProminence = 0;
    nullMaxWidth = round(m/2);
    nullMinWidth = 0;
    nullDistance = 0;

    %We define a minimum FSR of 2nm to define the number of peaks that 
    %could comprehensibly be in a defined spectrum.
    maxnPeaks = round(R/2);  
            
    factive = filterStat(1)|filterStat(2)|filterStat(3)|filterStat(4)|filterStat(5);
    if (factive)
        if filterStat(1), Height = filterParam(1); else, Height = nullHeight; end 
        if filterStat(2), Prominence = filterParam(2); else, Prominence = nullProminence; end            
        if filterStat(3), MaxWidth = round (filterParam(3)/Distunit); else, MaxWidth = nullMaxWidth;   end
        if filterStat(4), MinWidth = round (filterParam(4)/Distunit); else, MinWidth = nullMinWidth;  end
        if filterStat(5), Distance = round (filterParam(5)/Distunit); else, Distance = nullDistance;   end

        [~,locs]= findpeaks(E,'MinPeakHeight',Height,'MinPeakProminence',...
            Prominence,'MaxPeakWidth', MaxWidth, 'MinPeakWidth', ...
            MinWidth, 'MinPeakDistance', Distance,'Annotate','extents');

        if length(locs)>maxnPeaks && ~isempty(locs)
            %Tries to invert the field and find the peaks
            [~,locs]= findpeaks(-E,'MinPeakHeight',-Height,'MinPeakProminence', Prominence,'MaxPeakWidth', MaxWidth, 'MinPeakWidth', MinWidth, 'MinPeakDistance', Distance,'Annotate','extents');
        end

        if ~isempty(locs)>0
            lambda = x(locs); 
            pks = E(locs);
        end
    end
     
end


