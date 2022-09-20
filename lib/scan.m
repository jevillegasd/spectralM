function nData = prepareScan(g)
    %Run a continous sweep scan
    
    scanData.output = 0;            % 0 = HighPower (Laser Output Port 2), 1 = LowSSE (Laser Output Port 1)                   
    scanData.power = 0;             % Power in dBm (0dBm = 1mW)  
    scanData.starWav =  1400*1e-9;  % start wavelength in m
    scanData.stopWav =  1600*1e-9;  % stop wavelength in m
    scanData.step =     0.01*1e-9;  % Stepsize in meters
    scanData.pwmChannel = 0;        % 0 = 1st PM Channel
    scanData.sweepSpeed = 2*1e-9;   % Sweep speed in m/s
    scanData.range = -10;           % Range in dBm in steps of 10, between [-70 and 40];

    nData = scanData;
    
    %fopen(g);
    %fprintf(g,'disp:enab 0');
    
    %% Prepare for a continous lambda scan

    %Sets start and stop points for the sweep
    scanData.starWav*1e9
    send(g,"sour0:wav:swe:star "+num2str(scanData.starWav*1e9,'%4.1f')+ "nm");
    nData.starWav = str2num(send(g,"sour0:wav:swe:star?"));
    fprintf(g,"sour0:wav:swe:stop "+num2str(scanData.stopWav*1e9,'%4.1f')+ "nm");
    fprintf(g,"sour0:wav:swe:stop?");nData.stopWav = str2num(fscanf(g));
    
    %Query the maximum possible power to run the sweep, and sets the power
    fprintf(g,'wav:swe:pmax? 1540nm,1550nm');pmax = str2num(fscanf(g));
    pwr = min(scanData.power,pmax);
    fprintf(g,"sour0:pow "+num2str(pwr,'%2.4f'));
    fprintf(g,"sour0:pow?"); nData.power = num2str(pwr,'%2.4f');
    
    %Set the sweep step size in nm 
    fprintf(g,"wav:swe:step "+num2str(scanData.step*1e9,'%2.3f')+"nm");     pause(0.1);
    fprintf(g,"wav:swe:step?");nData.step = str2num(fscanf(g));
    
    %Check for the step frequency to be below 40kHz and uptades the speed
    sws = scanData.sweepSpeed;
    w = sws/nData.step;
    if w >= 4e4
       sws =  4e4*nData.step; %max speed for a sampling frequency of 40kHz
    end
    fprintf(g,"wav:swe:spe? Max"); 
    maxs = str2num(fscanf(g))*1e-9; %maximum reachable speed
    scanData.sweepSpeed = min(sws,maxs);
    
    %Set the sweep speed
    fprintf(g,"sour0:wav:swe:spe "+num2str(scanData.sweepSpeed*1e9,'%2.1f')+"nm/s");
    fprintf(g,"sour0:wav:swe:spe?");nData.sweepSpeed = str2num(fscanf(g));
    send(g,'wav:swe:cycl 1');
    
    stat = send(g,'sour0:wav:swe:chec?')
    cyc = send(g,'wav:swe:cycl?');
    trigs = send(g,'sour0:wav:swe:exp?');
    
    
%     %% Final Setup of Scan
%     fprintf(g,'sour0:wav:swe:mode CONT'); %Set the sweep mode to continous
%     fprintf(g,'trig1:outp STF');          %Set the trigger at every  sweep step
%     fprintf(g,'sour0:am:stat 0');         %Turn off the source modulation
%     
%     
%     
%     
%     %% Start Scan
%     logStat =1;
%     fprintf(g,'sour0:wav:swe:llog 1'); %Starts the logging of data
%     while logStat
%         fprintf(g,'sour0:wav:swe:llog?'); logStat = fscanf(g); %0 if the logging is switch off
%         disp(logStat)
%         %add status bar and option to stop sweep.
%     end
%     
%     
%     
%     %fprintf(g,'outp0:path?'); fscanf(g) %read the regulated output path
%     %fprintf(g,'outp0?'); fscanf(g)      %read the current state of the laser
%     %fprintf(g,'sour0:am:stat?'); fscanf(g)  %state of the amplitude modulation
%     %fprintf(g,'sour0:chan1:pow?'); fscanf(g)%power output of the laser
%     
%     
%     fprintf(g,'disp:enab 1')
%     fclose(g)


%     
%     
%     pwrUnit = 0;        %0 dBm / 1: mW
%     noscans = 0;        %0: 1 scam / 1: 2 scans / 2: 3 scans
%     pwmChannels = 3;    %
%     
%     resetDefault = 0;   %
%     rangeDecrement = 30;%
%     
%     deviceObj = icdevice('hp816x.mdd','GPIB0::20::INSTR');
%     connect(deviceObj)
%     groupObj = get(deviceObj, 'Applicationswavelengthscanfunctionsmultiframelambdascan');
%     
%     invoke(groupObj,'registermainframe'); %registering mainframe
%     invoke(groupObj,'setsweepspeed',scanData.sweepSpeed);
%     [dataPoints,channels] = invoke(groupObj,'preparemflambdascan',...
%         pwrUnit, scanData.power,scanData.output,...
%         noscans,pwmChannels,...
%         scanData.startWav,scanData.stopWav,scanData.step);
%     lambda = zeros(1,dataPoints);
%     
%     invoke(groupObj,'setinitialrangeparams',scanData.pwmChannel,resetDefault,scanData.range,rangeDecrement);
%     
%     [mfStart,mfStop,mfAvgTime,mfSweepSpeed] = invoke(groupObj,'getmflambdascanparametersq');
%     
%     pause
%     [lambda] = invoke(groupObj,'executemflambdascan', lambda);
    
   
    
end