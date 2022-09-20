function [comboStrings,comboValues]= getComboData(connection, type)
% Update AttenuatorDropDown
            c_att = 0; 
            comboStrings = [""]; comboValues=[];
            
            for i =1:size(connection,1)
                c = connection(i);
                if ~isempty(c.instr)

                    if c.config.Type==type
                        c_att = c_att +1;
                        comboStrings(c_att) = strcat(string(c.ID),'::',c.config.Name);
                        comboValues(c_att) = c.ID;
                    end
                end
            end
