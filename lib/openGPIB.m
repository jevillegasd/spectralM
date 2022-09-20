%This will leave an GPIB connection open, and do nothing otherwise if its
%not a GPIB type of connection.
function closeConn = openGPIB(g)

    closeConn = false;  
    if isa(g,'visa')
        if strcmp(g.status,'closed')
            closeConn = true; 
            fopen(g);  
        end
    elseif isa(g,'tcpclient')
        closeConn = false;    
    elseif isa(g,'sm_instrument')
        closeConn = openGPIB(g.connection);
    else   
        error('Unsopported type of variable.');
    end