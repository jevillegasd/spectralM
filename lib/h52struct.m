function struct = h52struct(file, loc)
    if nargin == 1, loc = '/'; end
    isStructArray = 0;
    struct = []; hinfo = [];
    hinfo = h5info(file, loc);
    
    %Read groups in the datasets and itterates on them
    %It assumes that arrays of structures are split attributes with a
    %numeric value indicating its index in the strcuture.
    for i =  1: length(hinfo.Groups)
        attloc = hinfo.Groups(i).Name;
        splitStr = split(attloc,'/'); 
        attnam = splitStr{end};
        attnum = str2num(attnam);
        attstruct = h52struct(file,attloc);
        if isempty(attnum)
            struct.(attnam) = attstruct;
        else
            isStructArray = 1;
            struct{attnum} = attstruct;
        end
    end
    
    %Save datasets to named variables in the structure 
    if ~isStructArray
        for i =  1: length(hinfo.Datasets)
            attnam = hinfo.Datasets(i).Name;
            attloc = [loc , '/',attnam];
            attval = h5read(file,attloc);
            struct.(attnam) = attval;
        end
    end
    
    %disp(hinfo)
end