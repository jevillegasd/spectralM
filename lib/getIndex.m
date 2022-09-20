%This function search for a spoecific measurement ID and returns the index
%where it was found inside of a measurements data structure.
%Part of Spectral Measurements
%Copyrights NYU 2019
%Developed by Juan Villegas
%31/7/2019
function index = getIndex(data,ID)
    index = 0;
    for i = 1: length(data)
        if data{i}.ID == ID
            index = i;
            return;
        end
    end
end


