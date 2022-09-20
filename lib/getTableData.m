function t = getTableData(pdata)
%Reads a measurement structure and builds a table with the ID, Date,
%Var1,Var2 and Var3
%Part of SpectralMeasurements
%Copyright NYU 2019
%Develloiped by Juan Villegas
%31/07/2019

    sizeP = length(pdata);
    ID = zeros(sizeP,1); Var1 = ID; Var2 = ID; Var3 = ID; 
    Date = strings(sizeP,1); %Initialize data for the table
    Description = strings(sizeP,1); %Initialize data for the table
    for i = 1:sizeP
        ID(i)=pdata{i}.ID;
        Date{i} = datestr(pdata{i}.time,'mmmdd_THHMMSS');
        if( isfield( pdata{i},'desc'))
            Description{i} = char(pdata{i}.desc);
        else
            Description{i} = char("");
        end
        Var1(i) =  pdata{i}.var(1);
        Var2(i) =  pdata{i}.var(2);
        Var3(i) =  pdata{i}.var(3); 
    end
    t = table(ID,Date,Description,Var1,Var2,Var3);
end