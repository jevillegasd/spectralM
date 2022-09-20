function data = getDataStream(fid,cmd,strPrecision)
if (isa(fid,'sm_instrument'))
    fid = fid.connection;
end
sm_flush(fid);

%%Read IEEE little indian stream of data
    data = [];
    if strcmp(strPrecision, 'float')
        precision = 4;
        strPrecisionTCP = 'single';
    elseif strcmp(strPrecision, '2-byte')
        precision = 2;
        strPrecisionTCP = 'uint16';
    elseif strcmp(strPrecision, 'double')
        precision = 8;
        strPrecisionTCP = strPrecision;
    else
        return;
    end
    
    try
        if isa(fid,'visa')
            fprintf(fid,cmd);
            c = fread(fid,1,'uint8');

            if c == 35 
                c = fread(fid,1,'char');
                bws = str2double(c);
                if isnan(bws)
                    warning('Response canot be processed.');
                end
                c = fread(fid,bws,'char');
                size = floor(str2double(c)/precision);
                data = nan(size,1);
                for i = 1:size
                    dat = fread(fid,1,strPrecision);
                    data(i) = dat;
                end
            else
                data = []; %Wrong header in the data stream error 
            end
        elseif isa(fid,'tcpclient')  
            %% Its a tcp client
            writeline(fid,cmd);
            c = read(fid,1,'uint8');

            if c == 35 
                c = read(fid,1,'char');
                bws = str2double(char(c));
                c = read(fid,bws,'char');
                size = floor(str2double(char(c))/precision);
                data = nan(size,1);
                for i = 1:size
                    dat = read(fid,1,strPrecisionTCP);
                    data(i) = dat;
                end
            else
                data = []; %Wrong header in the data stream error 
            end

        else
            data = []; %Wrong header in the data stream error 
        end
    catch EM
        warning(EM.message);
    end
    sm_flush(fid);
end