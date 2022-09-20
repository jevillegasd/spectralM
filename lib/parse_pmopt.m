function pm_opt = parse_pmopt(s)
    c = char(s);
    %We need to parse this answer
    l = str2double(c(2));
    bytes = 0;
    for i = 1:l
        bytes = bytes+str2double(c(2+i))*10^(l-i);
    end
    j = 0; pm_opt = [];
    if length(c)>=5+bytes
        for i = 3+l:4:2+l+bytes
            j = j+1;
            pm_opt(j).slot = double(c(i));
            pm_opt(j).channel = double(c(i+2)); 
        end
    end