function slot =  get_pmconfig(fid)
    cmd =  sprintf('read1:pow:all:conf?');
    data = getDataStream(fid,cmd,'2-byte');
    if (isempty(data))
        slot = [];
        return
    end
    slot.number = data(1);
    channel =  [data(2)];
    slot = [slot];
    nslot = 1;
    for(i=3:2:length(data))
        if data(i) ~= slot(nslot).number
            slot(nslot).channel = channel;
            nslot = nslot + 1;    
            newslot.number = data(i);
            newslot.channel = [];
            slot = [slot newslot];
            channel = [];
        end 
        channel =  [channel data(i+1)];
    end
    slot(nslot).channel = channel;
end

