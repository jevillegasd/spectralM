function param = setup_pm(fid,param)
    sm_flush(fid);
    pm_slot     = param.pm_slot; 
    pm_channel  = param.pm_channel;    
    star_wav    = param.starWav;    %m
    stop_wav    = param.stopWav;    %m
    step_size   = param.step;       %m
    scan_speed  = param.sweepSpeed; %m/s
    avg_time    = param.avgTime;    %s
    ls_power    = param.power;      %mW
    rang        = param.range;      %dBm
    trigs       = param.trigs;
    self        = param.self;
    
    center_wav  = (stop_wav + star_wav)/2;

    send(fid,'sens%1d:pow:atim %1.5fms',pm_slot,avg_time*1e3);  % Sets the averaging time in seconds
    avg_time = str2double(send(fid,'sens%1d:pow:atim?',pm_slot));      % Checks the averaging time

    send(fid,'sens%1d:pow:rang:auto 0',pm_slot);        % Sets the power range to not auto
    send(fid,'sens%1d:pow:rang %1dDBM',pm_slot, rang);  % Sets the power range of the instrument
    send(fid,'sens%1d:pow:unit 0',pm_slot);             % Sets the sensor power unit to dBm
    rang = str2double(send(fid,'sens%1d:pow:rang?',pm_slot));

    send(fid,'sens%1d:pow:wav %1dnm',pm_slot, center_wav);     %Set the reference wavelength for the measurement
    send(fid,'sens%1d:pow:wav?',pm_slot);

    if self
        send(fid,'trig0:inp sme'); 
        send(fid,'trig1:inp sme'); 
        trigInp = send(fid,'trig1:inp?');                    % Check the status of the trigger input configuration
    else
        send(fid,'trig1:inp ign');                           % 
        send(fid,'trig2:inp sme');                           % Sets the instrument to perform a measurement on every trigger
        trigInp = send(fid,'trig1:inp?');                    % Check the tatus of the trigger input configuration
    end
   
    if ~self
        send(fid,'trig2:conf def');           % Enables the hardware trigger when there is an external power meter
    else
        send(fid,'trig0:conf loop');          % If its integrated we need to maintain the loop configuration
        send(fid,'trig1:conf loop');          % If its integrated we need to maintain the loop configuration
    end
    %send(fid,'sens1:func:stat logg,star');
    
    % Setup the logger
    send(fid,'sens%1d:chan%1d:func:par:logg %1d, %1.5f',pm_slot,pm_channel,trigs,avg_time);
    
    %% Update parameters  
    param.starWav = star_wav;    %m
    param.stopWav = stop_wav;    %m
    param.step = step_size;       %m
    param.sweepSpeed = scan_speed; %m/s
    param.avgTime = avg_time;    %s
    param.power = ls_power;      %mW
    param.range = rang;      %dBm
end