function opcStat = wait_OPC(g, timeout)
    tic; opcStat = 0;
    while opcStat ~=1 && toc<timeout, opcStat = str2double(send(g,'*OPC?')); end
end