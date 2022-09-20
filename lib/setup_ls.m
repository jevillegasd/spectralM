%% 
% This fucntion setups the parameters for a lambda scan on a Laser Source.
% The input parameters is a structure with all the necessary configuration
% to carry the lambda scan, and returns and updated structure with the
% actual parameters that were configured. Sucha paramteers might change
% depending on the instrument working limits.

function param = setup_ls(fid, param)   
    ls_slot     = param.ls_slot;    
    star_wav    = param.starWav;    %m
    stop_wav    = param.stopWav;    %m
    step_size   = param.step;       %m
    scan_speed  = param.sweepSpeed; %m/s
    avg_time    = param.avgTime;    %s
    ls_power    = param.power;      %mW
    rang        = param.range;      %dBm
    self        = param.self;       %Flag if the power meter is part of the power LMS.
    speeds_opt = [0.5 1 2 5 10 20 40 50 80 100]*1e-9;
    
    % Set the scanning wavelength
    send(fid,"sour%1d:wav:swe:star %4.1fnm",ls_slot, star_wav*1e9);  pause(0.01);      
    star_wav = str2double(send(fid, "sour%1d:wav:swe:star?", ls_slot));
    
    send(fid,"sour%1d:wav:swe:stop %4.1fnm",ls_slot, stop_wav*1e9); pause(0.01);     
    stop_wav = str2double(send(fid,"sour%1d:wav:swe:stop?",ls_slot));

    %Query the maximum possible power to run the sweep, and sets the power
    pmax = 10*log10(1e3*str2double( ...
            send(fid,"wav:swe:pmax? %4.1fnm,%4.1fnm", star_wav*1e9, stop_wav*1e9)));
        
    %ls_power = min(ls_power,pmax);
    %%Double check why this fucntion sometimes is setting a very low power
    %%as mnaximum
    
    
    send(fid,"sour%1d:pow %2.1f", ls_slot, min(pmax,ls_power));   
    ls_power_tmp = str2double(send(fid, "sour%1d:pow?", ls_slot));
    if (ls_power_tmp ~= ls_power)
       warning(strcat('Power level configuration error: Power set to ',num2str(ls_power_tmp))); 
       ls_power = ls_power_tmp;
    end
    
    %Set the step size
    send(fid,"wav:swe:step %2.3fpm",step_size*1e12);  pause(0.01);        
    step_size_tmp = str2double(send(fid,"wav:swe:step?"));
    if (round(step_size_tmp*1e12) ~= round(step_size*1e12))
       warning(strcat('Step size configuration error: Step size set to ',num2str(step_size_tmp))); 
       step_size = step_size_tmp;
    end
    
    send(fid,"wav:swe:mode CONT");
    sweep_mode = (send(fid,"wav:swe:mode?"));
    %disp(strcat("Sweep mode: ", sweep_mode));
    
    %Set cycles and test  number of triggers
    send(fid,'wav:swe:cycl 1');                           
    cycle = str2double(send(fid,'wav:swe:cycl?'));
    trigs = str2double(send(fid,'sour%1d:wav:swe:exp?',ls_slot)); %this needs to be below 1e5

    if trigs > 1e5
       id = 'SpectraMeasurements:InstrumentStatus:Sweep';
       msg = 'The instrument configuration is not appropiate for a sweep, increase the step size.';
       ME = MException(id,msg);
       throw(ME); 
    end
    
    %Define a scan speed within work boundaries (restrictions are defined by the
    %sample size, the scan speed limits, the measurememt frequency and the
    %minimum averaging time.
    
    
    maxs = str2double(send(fid,"wav:swe:spe? Max"))*1e-9;
    
    if scan_speed == 0, scan_speed = maxs/10; end
    [~,idx] = min(abs(maxs-speeds_opt));
    maxs = speeds_opt(idx); % Force the max speed to one pf the options
    
    [~,idx] = min(abs(scan_speed-speeds_opt));
    scan_speed = speeds_opt(idx); % Force the scan speed to one of the options
    
    w = (scan_speed)/step_size; %Sampling frequency
    if w >= 4e4
        warning('The speed configuration is higher than allowed for the step size input. Automatically adjusting.'); 
        scan_speed = maxs;
    end
    scan_speed = min(scan_speed,maxs);
    
    send(fid,"sour%1d:wav:swe:spe %3.1fnm/s",ls_slot,scan_speed*1e9);
    scan_speed = str2double(send(fid,"sour%1d:wav:swe:spe?",ls_slot));
    
    scanTime = abs(stop_wav - star_wav)/(scan_speed);
    maxAvgTime = scanTime/trigs/2;
    minAvgTime = 1e-4;

    if avg_time < minAvgTime
       warning('The resulting averaging time is too low, automatically updating parameters to adjust.');
       avg_time = minAvgTime;
    elseif avg_time > maxAvgTime
        avg_time = maxAvgTime;
        %warning('The resulting averaging time is too high, automatically updating parameters to adjust.');
    end
    avg_time = max(round(avg_time/2,5)*2,minAvgTime);
    
    avg_time = round(avg_time/2,4)*2;
    trigger = 0; %This should be the slot number in the LMS
    
    % reset the input trigger behaviour (IGN by default)
    send(fid,'trig%1d:inp IGN',0);
    send(fid,'trig%1d:inp IGN',1);
    
    %Setup the output trigger behavior
    
    send(fid,'trig%1d:outp STF',trigger);             % STF: Sends a trigger when a step finsihes.
    trigOut = send(fid,'trig%1d:outp?',trigger);    
    
    send(fid,'trig%1d:conf LOOP',trigger) ;           % We need the trigger to loop even when using internal 
    congOut = send(fid,'trig%1d:conf?',trigger);      % power meter to logg the wavelength data
    
    % DEBUG: The trigger pointed to should be the slot where there is a
    % power measurement system. 
    
    chec = char(send(fid,'sour%1d:wav:swe:chec?',ls_slot));
    checc = str2double(chec(1));
    if isnan(checc)
        stat = 0;
    else, stat = ~(checc);
    end
    
    if ~stat
       id = 'SpectraMeasurements:InstrumentStatus:Sweep';
       msg = 'The instrument configuration is not appropiate for a sweep';
       ME = MException(id,msg);
       throw(ME); 
    end
    
    %% Update parameters  
    param.starWav = star_wav;    %m
    param.stopWav = stop_wav;    %m
    param.step = step_size;       %m
    param.sweepSpeed = scan_speed; %m/s
    param.avgTime = avg_time;    %s
    param.power = ls_power;      %mW
    param.range = rang;          %dBm
    param.trigs = trigs;
    param.scanTime = scanTime;
end