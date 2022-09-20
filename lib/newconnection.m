function [outputArg1, errorstack] = newconnection(configData)
    %   Untitled Summary of this function goes here
    %   Detailed explanation goes here
    outputArg1 = []; iconn = 0; errorstack = [];
    
    %% We make a list of available IP addresses in the local network to restrict quering connections to them
    [~,result] = system('arp -a');
    str = splitlines(convertCharsToStrings(result));
    ipaddresses = strings(length(str)-4,1);
    j=0; %Counter to check for empty line feeds, which appear at the interface changes
    for i=1:length(ipaddresses)
        if i+j*3 < length(str)
            if str(i+j*3)=="" 
                j=j+1;
            end
            ipaddresses(i) = strtrim(extractBetween(str(i+j*3),3,17));
        end

    end
    ipaddresses = ipaddresses(~all(ipaddresses=="",2)); %Clean up all the empty rows
    clear('s','str','result',"i","j");

    %% 
    for i =1:size(configData,1)
        iconn = iconn+1;
        c = configData(i,:);
        new_connection = struct('config',[],'ID',[],'type',[],'instr',[],'status',[]);
        new_connection.config = c;
        new_connection.ID = c.ID*10;
        new_connection.type =  c.Interface;
        new_connection.status = c.Enabled;
        new_connection.slot = 0;
        new_connection.slotconfig = [];
        try
            if (new_connection.type=="visa") && new_connection.status
                new_connection.instr = sm_instrument(string(c.vendor), c.Board, c.GPIB);
                new_connection.status = true;
            elseif (new_connection.type == "TCPIP") && new_connection.status
                if any(strcmp(ipaddresses,c.("IP Address")))
                    new_connection.instr = [];
                    new_connection.instr = sm_instrument(char(c.("IP Address")));
                    new_connection.status = true; 
                else
                    new_connection.instr = [];
                    new_connection.status = false; 
                end
            else
                new_connection.instr = [];
                new_connection.status = false;
            end
        catch ME
           new_connection.status = false;
           warning(ME.message);
           errorstack = [];
           % warning("Exception thrown in " + ME.stack(1).name +", in line "+ ME.stack(1).line);
        end

        % If an instrument is a mainframe, query its slots and get each
        % of the available modules, and make a list with all modules
        % available. If its a power meter or an attenuator (to be done),
        % identify the configuration of slots and channels.

        slot_list = [];
        if (new_connection.config.Type == "Mainframe") && new_connection.status
            slot_list = getSlots(new_connection);
        elseif (new_connection.config.Type == "Power Meter") && new_connection.status
             new_connection.slotconfig = get_pmconfig(new_connection.instr.connection);
        end
        outputArg1 = [outputArg1;new_connection;slot_list];
    end

end

