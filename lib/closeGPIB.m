function closeGPIB(g)
    if isa(g,'visa')
        if strcmp(g.status,'open')
            fclose(g);  
        end
    elseif isa(g,'tcpclient')
  
    elseif isa(g,'sm_instrument')
        closeGPIB(g.connection);
    else   
        error('Unsopported type of variable.');
    end