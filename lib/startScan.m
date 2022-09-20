function setupScan(g,sweepP)
    %% Final Setup of Scan
    send(g,'sour0:wav:swe:mode CONT'); %Set the sweep mode to continous
    send(g,'trig1:outp STF');          %Set the trigger at every  sweep step
    send(g,'sour0:am:stat 0');         %Turn off the source modulation
    
    %Start the 
    send(g,"sens1:func:par:logg "+num2str(sweepP.trigs)+","+1e-3+"s")
    send(g,'sens1:func:stat logg,star');
    
    % Start the source wevelength logging
    send(g,'sour0:wav:swe:llog 1');     %Starts the logging of data
    
    %% Start the sweep
    send(g,'sour0:wav:swe 1');                %Runs the sweep
end