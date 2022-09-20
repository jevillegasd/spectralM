function data = get1DData(obj,opt)
    data = []; 
    %% Parse the option 
    var = "";
    if strcmp(opt,"")
        return;
    elseif strcmp(opt,"wavelength")
        var = "spectra";
        index = 1;
    elseif strcmp(opt,"intensity")    
        var = "spectra";
        index = 2; 
    elseif strcmp(opt,"time")
        var = "time";
        index = 1;
    elseif strcmp(opt(1:3),"var")
        var = "var";
        index = str2double(opt(4:end));
    else
        obj2 = cell(size(obj));
        for i = 1: length(obj)
            obj2{i} = obj{i}.peakAnalysis;
        end
        obj = obj2;
        if strcmp(opt,"Resonance Wav.")
            var = "wav";
            index = 1;
        elseif strcmp(opt,"FSR")
            var = "fsr";
            index = 1; 
        elseif strcmp(opt,"FWHM")
            var = "fwhm";
            index = 1;
        elseif strcmp(opt,"Q. Factor")
            var = "q";
            index = 1;
        elseif strcmp(opt,"Group Index")
            var = "ng";
            index = 1; 
        end
    end
    
    
    %% Extract the data
    
    for i = 1: length(obj)
        adata = obj{i}.(var);
        adata = adata(:,index);
        data(:,i) = adata;
    end
    if size(data,1) == 1 %Transpose single row arrays
        data = data';
    end
end