function lock_laser = lock(g, val)
    lock_laser = 0;
    if str2double(send(g,'lock?'))
        send(g,['lock ', num2str(val), ',1234']);
        lock_laser = str2double(send(g,'lock?'));
    end

