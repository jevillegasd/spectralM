
filen = 'G:\My Drive\PRL Group\04 Projects\2 Juan\2 OPUF Chip01\5 Input Power Stability\PUF User Test\20210322\OPUF01_DEV04.smp'

struct = h52struct(filen)


meas = struct.project.measurements;
m = meas{1}.spectra;
figure(2), plot(m(:,2))
figure(1)
all = zeros(length(m),length(meas));
for i = 1:length(meas)
    m = meas{i}.spectra;
    all(:,i) = m(:,2);
end

surf(all); shading interp; colormap hot