%Defintion
% instr = sm_instrument("192.168.1.105")   - For a TCP/IP Connection
% instr = sm_instrument("keysight",32,20)  - For a GPIB Connection

classdef sm_instrument
   properties
        type
        connection
        manufacturer
        model
        serial
        firmware
        status
        slots  = [""];
        nslots
   end
   
   methods
      function delete(obj)
        if strcmp(bj.type,"gpib")
            fclose(obj.connection);
            delete(obj.connection);
        end
      end
      
      function obj = sm_instrument(ipaddress, gpib_index, gpib_address)
          pm_list = {'7744A','81635A','81618A'};  %List of power meters
          
         %% Configure connection based on the number of arguments used as input
         if nargin <3
            obj.type = "tcpclient";
            obj.connection = tcpclient(ipaddress, 5025,'Timeout',2, 'ConnectTimeout',10);
            if (isempty(obj.connection))
                Em = MException('SpectralM:COM:InstrNotFound','The instrument specified is not reachable.');
                throw(Em);
            end
         elseif nargin > 2
            obj.type = "gpib";
            vendor = ipaddress;
            visconn = strcat('GPIB',num2str(gpib_index),'::',num2str(gpib_address),'::INSTR');
            g = findInstrument(visconn);
            if isempty(g)
                Em = MException('SpectralM:COM:InstrNotFound','The instrument specified is not reachable.');
                obj.status = 0;
                throw(Em);
            else
                obj.connection = g;   
            end
         end
         obj.slots = [""];
         obj.nslots = 0;
         
       %% Get basic information from the instrument
        s = send(obj.connection,instrid);
        if (isempty(s))
            Em = MException('SpectralM:COM:NoResponse','There is no complete response from the instrument in the configured Timeout period');
            obj.manufacturer ='NA';
            obj.model = 'NA';
            obj.serial ='NA';
            obj.firmware = 'NA'; 
            obj.status = 0;
            fclose(obj.connection);
            throw(Em);
        else
            stream = strtrim(strsplit(s,','));
            obj.manufacturer = stream(1);
            obj.model = stream(2);
            obj.serial = stream(3);
            obj.firmware = stream(4); 
            obj.status = 1;
        end
        
        %% Get number of slots in the instrument
        s = send(obj.connection,'*OPT?');
        if (~isempty(s))
            if any(strcmp(pm_list,obj.model)) %Is it a power meter?
                pm_opt = parse_pmopt(s);    
                obj.slots = string(pm_opt.slot);
                obj.nslots = length(stream,pm_opt.slot);  
            else
                stream = strtrim(strsplit(s,','));
                obj.slots = string(stream);
                obj.nslots = length(stream);   
            end
        end
      end
   end
end