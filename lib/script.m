
%Read the spectral response of the power sensors

fprintf(g,'slot1:head1:wav:resp:csv?');
bufsize = g.inputBufferSize;
bytesRead = bufsize;

while bytesRead >= bufsize
    a = fscanf(g);
    s = [s,a];
    bytesRead = size(a,2);
end

i = 1;
while(double(s(i))~=10), i = i+1;end %look for the first return character
s = s(i+1:end);
spectrum = str2num(s);


if ~isempty(spectrum)
    fprintf(g,'slot1:head1:wav:resp:size?');
    s = fscanf(g);
    spSize=str2num(s);
    spectrum = spectrum(1:spSize,:);
    plot(spectrum(:,1),spectrum(:,2));
end





