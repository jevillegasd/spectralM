%Runs a sweep on a keysight/agilent Lightwave measurement system.
%Part of Spectral Measurements
%Copyright NYU 2019
%Developed by Juan Villegas
%06/01/2019
%Updated in May 2021, 

function result = runSweep(ls_conn ,pm_conn ,param)
    sm_flush(ls_conn), sm_flush(pm_conn);
    result = [];
    
    out = timerfind; t = out(1); tim_stat = strcmp(t.running,'on');
    stop(t);
    
    pm_channel  = param.pm_channel;
    pm_slot     = param.pm_slot;    
    ls_slot     = param.ls_slot;    
    star_wav    = param.starWav;    %m
    stop_wav    = param.stopWav;    %m
    step_size   = param.step;       %m
    scan_speed  = param.sweepSpeed; %m/s
%     avg_time    = param.avgTime;    %s
%     ls_power    = param.power;      %mW
    range       = param.range;      %dBm

    scanTime    = param.scanTime;
    timeout     = round(scanTime,10)+15;
    
    send(ls_conn,"outp%1d 1",ls_slot);           % Turn on laser
    send(pm_conn,'sens%1d:chan%1d:func:stat logg,star', pm_slot, pm_channel);  %Starts the logging of power data  

    opcStat = 0; tic;
    while ~opcStat && toc<timeout
        opcStat1 = str2double(send(pm_conn,'*OPC?')); 
        opcStat2 = str2double(send(ls_conn,'*OPC?')); 
        if ~isnan(opcStat1) &&  ~isnan(opcStat2)
            opcStat = opcStat1 & opcStat2;
        end
    end
        
    send(ls_conn,'wav:swe:llog 1');                 % Starts the logging of wavelength data  \
    send(ls_conn,'sour%1d:wav:swe 1', ls_slot);     % Runs the sweep    
    
    tic;
    %% Wait for the laser finishing sweeping
    try while str2double(send(ls_conn,'sour%1d:wav:swe?',ls_slot)) ...
        && toc<timeout, pause(1), end
    catch EM, end
    
    if toc>= timeout,   warning('Sweep timed-out');  end

    %% Wait for the power system finishing logging
    try while contains(send(pm_conn,"sens%1d:chan%1d:func:stat?",pm_slot,pm_channel),'PROGRESS') ...
        && toc<timeout, end
        if (toc>timeout), warning('Sweep measurement timed out.'); end
    catch EM, end
    send(ls_conn,'outp%1d 0',0); % Turn off laser
    
    %% Read Wavelength and Scan Data
    cmd = sprintf('sour%1d:read:data? llog',ls_slot);
    wav = getDataStream(ls_conn,cmd,'double');
    if isempty(wav)|| length(wav)<=1
       warning('Error loading wavelength data. Automatically assigned an array matching the sweep configuration.'); 
       wav = [star_wav:step_size:stop_wav]'; 
    end
    
    cmd = sprintf('sens%1d:chan%1d:func:res?',pm_slot,pm_channel);
    powdb = getDataStream(pm_conn,cmd,'float');
    pause(0.1);
    send(pm_conn,'sens%1d:chan%1d:func:stat logg, stop', pm_slot,pm_channel); 
    
    opcStat = 0; tic;
    while ~opcStat && toc<timeout, opcStat = str2double(send(pm_conn,'*OPC?')); end
    send(pm_conn,'trig%1d:inp IGN',pm_slot);
    
    if (isempty(powdb))
       result = [];
       if tim_stat
            start(t);
       end
       return;
    end
    unit = double(send(pm_conn,'sens%1d:chan%1d:pow:unit?', pm_slot,pm_channel));
    mini = min(powdb,[],'all');
    refp_db = 0.01;
    if abs(mini)<refp_db || unit
        %Data was probably sent in W and not dB so trasnform it
        warning('Data automatically transformed to dB')
        pow = powdb;
        powdb = real(10*log10(pow*1000));
    end
    
    min_pdb = -100;
    minP_W = 10^((range-60)/10)*1000;
    
    %pow(pow==-200)= minP_dB; %This is in case the data is in dBm. Change to check what the PM is set to
    %powdb = 10*log10(pow*1000);
    
    %Filter any "zeroed" data points based on the range
    powdb(powdb < -100) = min_pdb; 

    result = [wav,powdb];
    if tim_stat
        start(t);
    end
end