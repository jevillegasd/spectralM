
function power = readpower(g)
    if (~isa(g,'sm_instrument'))
       Em = MException('SpectralM:type:TypeMismatch','This functions input type are not matching.');
       Throw(Em);
    end
    
    s = send(g.connection,'read1:pow:all:conf?'); 
    str = char(s);
    
    %We need to parse this answer
        l = str2double(str(2));
        bytes = 0;
        for i = 1:l
            bytes = bytes+str2double(str(2+i))*10^(l-i);
        end
        j = 0; meter = [];
        for i = 3+l:4:2+l+bytes
            j = j+1;
            meter(j).slot = double(str(i));
            if (i+2)>length(str)
                meter(j).channel = 1;
                break;
            else
                meter(j).channel = double(str(i+2)); 
            end
        end
    %This is the list of slots available and their corresponding channels 
    
    for i=1:length(meter)
        send(g.connection,"sens"+num2str(meter(i).slot)+":pow:rang:auto 1"); 
        send(g.connection,"sens"+num2str(meter(i).slot)+":pow:unit 0");
        send(g.connection,"sens"+num2str(meter(i).slot)+":pow:atim 0.05"); 
        send(g.connection,"sens"+num2str(meter(i).slot)+":pow:wav 1550nm"); 
    end

    power=[];
    for i=1:length(meter)
        power(i) = str2num(send(g.connection,"read"+num2str(meter(i).slot)+":pow?")); 
    end
end