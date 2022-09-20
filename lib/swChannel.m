function slot = swChannel(instrument)
    slots = instrument.slots;
    sw_list = {'81595B'};                   %List of available switches
    slot = find(strcmp(slots, sw_list))-1;
    
    
end