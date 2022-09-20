function struct2h5(file, dataset, struct)
%Recursive function to write structures in h5 format.
%The function will also iterate through 1D cell arrays and save as
%individual datasets.
%Only supported file types int, double, struct char and strings, and cells
%containing the mentioned variable types.
%Part of Spectral Measurements
%Copyright NYU 2019
%Developed by Juan Villegas, 08/01/2019

    if nargin == 2
        dataset = '/dataset';
    end  
    
    if ~isempty(struct)
        if isstruct(struct)
            fn = fieldnames(struct);
            for k=1:numel(fn)
                field = struct.(fn{k});
                dataset2 = [dataset,'/',fn{k}];
                struct2h5(file, dataset2,field);
            end
        elseif iscell(struct)
            for i = 1: length(struct)
                datasetn = [dataset,'/',num2str(i)];
                struct2h5(file,datasetn,struct{i});
            end
        elseif isstring(struct) || ischar(struct)
            str2h5(file,dataset,struct);
        elseif isnumeric(struct) || islogical(struct)
            num2h5(file,dataset,struct)
        else
            warning(['Error with dataset <',dataset,'>: Variable type not supported.']);
        end
    else
        h5create(file,dataset,1);
    end
        
end

function num2h5(file,dataset,field)
    field = +real(field); %Convert logical in numeric values
    h5create(file,dataset,size(field));
    try
        h5write(file,dataset,field);
    catch Em
        disp(dataset); disp(num2str(field));
        throw(Em);
    end
end

function str2h5(filename,dataset,field)
%This function uses low level H5 calls to write char and strings to H5 files.
%Part of Spectral Measurements
%Copyright NYU 2019
%Develloped by Juan Villegas 08/01/2019

    cfield = char(field);
    
    if (cfield == 0 )
        return
    end
    
    DIM0 = size(cfield,1); 
    SDIM = size(cfield,2)+1;
    dcpl = 'H5P_DEFAULT';
    
    dims   = DIM0;
    file_id = H5F.open(filename,'H5F_ACC_RDWR',dcpl);  %Open the h5 file

    %Create file and memory datatype
    type_id = H5T.copy ('H5T_C_S1');
    H5T.set_size (type_id, SDIM-1);
    mem_id = H5T.copy ('H5T_C_S1');
    H5T.set_size (mem_id, SDIM-1);
    
    % Create dataspace.  Setting maximum size to [] sets the maximum
    % size to be the current size.
    space_id = H5S.create_simple (1, fliplr(dims), []);

    % Create the dataset and write the string data to it.
    try
       dataset_id = H5D.create (file_id, dataset, type_id, space_id, dcpl);
       % Transpose the data to match the layout in the H5 file to match C
        % generated H5 file.
        H5D.write (dataset_id, mem_id, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', cfield);
        H5D.close(dataset_id);
    catch Em
       %dataset_id = H5D.open (file_id, dataset);
       warning(Em.message) 
    end
    
    
    %Close and release resources  
    H5S.close(space_id);
    H5T.close(type_id);
    H5F.close(file_id);
    
end