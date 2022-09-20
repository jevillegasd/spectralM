function slot_list = getSlots(c)
    valueset = {'Mainframe' 'Laser Source' 'Attenuator ' 'Power Meter' ...
                'Return Loss' 'Switch' 'Polarization Controller'};
    numslots = c.instr.nslots;
    slot_list = [];
    
    pm_list = {'7744A','81635A','81618A'};  %List of power meters
    ls_list = {'81606A'};                   %List of available laser sources
    sw_list = {'81595B'};                   %List of available switches
    at_list = {'81577A','7762A'};           %List of available attenuators
    pc_list = {'7786B'};                    %List of available polarization controllers
    rl_list = {'81610A', '81634B'};
    
    close = false;
    if strcmp(string(c.type), "GPIB")
        fopen(c.instr.connection);
        close = true;
    end
    
    for j=0:numslots-1
        newslot = c;
        obj = c.instr;
        
        %Reset all values but the connection config
        obj.slots = ""; obj.nslots = 0; 
        obj.model = ''; obj.serial = ''; obj.firmware = ''; 
        obj.status = false;
        
        newslot.ID = c.ID+j+1;
        newslot.status = false;
        s = send(c.instr,"SLOT"+num2str(j)+":IDN?");
        stream = strtrim(strsplit(s,','));
        if length(stream)>1  
            obj = c.instr;
            obj.manufacturer = stream(1);
            obj.model = stream(2); 
            obj.serial = stream(3);
            obj.firmware = stream(4); 
            obj.status = 1;
            newslot.config.Description = "Slot member on mainframe"; 
            newslot.slot = j;
            newslot.config.Name = stream(2);
            newslot.slotconfig = [];
            if any(strcmp(pm_list,obj.model))
                newslot.config.Type =  categorical({'Power Meter'},valueset);
                newslot.slotconfig = get_pmconfig(obj);
            elseif any(strcmp(ls_list,obj.model))
                newslot.config.Type = categorical({'Laser Source'},valueset);
            elseif any(strcmp(sw_list,obj.model))
                newslot.config.Type = categorical({'Switch'},valueset);
            elseif any(strcmp(at_list,obj.model))
                newslot.config.Type = categorical({'Laser Source'},valueset);
            elseif any(strcmp(pc_list,obj.model))
                newslot.config.Type = categorical({'Polarization Controller'},valueset);    
            elseif any(strcmp(rl_list,obj.model))
                newslot.config.Type = categorical({'Return Loss'},valueset); 
            else
                newslot.config.Type = categorical({'[undefined]'},valueset);
            end
            newslot.status = true;
            
            % Check slot labels 
            s = send(obj,"SLOT"+num2str(j)+":OPT?");  
            if (~isempty(s))
                if any(strcmp(pm_list,obj.model)) || any(strcmp(rl_list,obj.model))  %Is it a power meter
                    %s = send(newslot.instr,"read"+num2str(j)+":pow:all:conf?");
                    stream = strtrim(strsplit(s,','));
                    if strcmp(stream(1),"NO CONNECTOR OPTION")
                        obj.slots = "";
                        obj.nslots = 1; 
                    else
                        obj.slots = string(pm_opt.slot);
                        obj.nslots = length(stream,pm_opt.slot);  
                    end
                else
                    stream = strtrim(strsplit(s,','));
                    obj.slots = string(stream);
                    obj.nslots = length(stream);   
                end
            end
            
            
        else
            newslot.config.Description = "";
            newslot.config.Name = "";
            newslot.config.Type = categorical({'[undefined]'},valueset);
            newslot.status = false;
            newslot.slot = 0;
        end
        newslot.instr = obj;
        slot_list = [slot_list ;newslot];
    end
    
    if close; fclose(c.instr.connection); end
end