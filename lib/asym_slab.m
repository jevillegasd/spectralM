% Asymetric slab solver (1D problems)
% Jaime Viegas
% Computational Electrodynamics MIC631 & 
% Photonic Materials and Devices MIC632
% Masdar Institute, UAE
% September 2012; 
% version 7: April 2014
% Following notation on Kawano&Kitoh, Optical Waveguide Analysis, pages 14 to 20
% --------Modified in the form of a function by Juan Villegas (2017)
function [neff,E,H] = asym_slab(lambda,n1,n2,n3,t,polarization,x)
% Initialization of fundamental constants
c = 299792458; % speed of light in vacuum (m/s) 
mu0 = pi*4e-7; % vacuum permeability (H/m)
eps0 = 1/(mu0*c^2); % vacuum permittivity (F/m)

%load('waveguide_data');

% Operational wavelength
% lambda = 0.66;
% n1 = 1.0;   %n1 = 1.446; %Bottom refractive index
% n2 = 1.6774;%n2 = 2;     %Core refractive index
% n3 = 1;     %Top refractive index
% 
% % n1 = 1.446; %Bottom refractive index
% % n2 = 2;     %Core refractive index
% % n3 = 1;%Top refractive index
% 
% t = 0.18;  %Slab thickness
% polarization='TM';

%calculation of internal constants (Kawano, eq. 2.13-1.15
k0 = 2*pi./lambda;
nmin = max([n1 n3]); % only the maximum value of the cladding material refractive indices is needed, as we are only interested on core-guided modes 
nmax = max([n1 n2 n3]);

if dot(size(lambda),size(lambda)) > 2 %uses a dot product to check if we are calculating for a fixed wavelength or a wavelength span (in this case dot(a,a)>2)
    neff_spacing = 0.0001; % for dispersion plot, the finer neff sampling is needed
else
    neff_spacing = 0.001; % generaly this neff sampling resolution is enough for the mode plots.
end

neff_divisions =  floor((nmax-nmin)/neff_spacing);
neff = linspace(nmin, nmax,neff_divisions);

switch upper(polarization)
    case {'TE'}
        for ii = 1:size(lambda,2)           %count for the number of wavelengths on the second dimension of lambda, as this is a row vector
            Y1 = k0(ii).*sqrt(neff.^2-n1^2);  % same as alpha in Chuang's textbook
            Y2 = k0(ii).*sqrt(n2^2-neff.^2);  % same as k1x in Chuang's texbook "Physics of Photonic Devices"
            Y3 = k0(ii).*sqrt(neff.^2-n3^2);  % same as alpha2 in Chuang's textbook
            LHS=Y2.*t;   

            neff_fnd = nmax;                                    
            q = 0;
            while neff_fnd > nmin
                RHS = atan(Y2./Y1)+atan(Y2./Y3)- (q+1)*pi;
                %plot(LHS); hold on; plot(RHS); hold off;
                Delta =-LHS-RHS;
                Loc = find(abs(Delta) == min(abs(Delta))); % may not be accurate as sometimes due to computational round-off values may not be zero
                neff_fnd = neff(Loc);
                ls_neff(ii,q+1) = neff_fnd;
                q = q+1;
            end
        end
        neff=ls_neff; % just keep the actual neff, erase the old trial values of neff
        neff = neff(neff>nmin);  % changes all the spurious neff which are not higher than nmin (max ncladding value) to NaN
              
        if dot(size(lambda),size(lambda)) == 2
            neff=neff(isfinite(neff)); %only keeps the finite values of neff (NaN values are discarded)
            number_of_roots = size(neff,2);
            a = k0*sqrt((min(neff))^2-nmin^2);
            %x=linspace(-1.5/(a*t),1.5/(a*t)+t,200);
            z=linspace(0,10*lambda/max(neff),200);
            Ey=zeros(number_of_roots,size(x,2)); 
            Ex = Ey; Ez = Ey; 
            Hx = Ey; Hy = Ey; Hz = Ey; 
            Y1=zeros(number_of_roots);
            Y2=zeros(number_of_roots);
            Y3=zeros(number_of_roots);
            counter = 1;
            for counter = 1:number_of_roots
                Y2(counter) = k0*sqrt(n2^2-(neff(counter))^2); % same as k1x in Chuang's textbook
                Y1(counter) = k0*sqrt((neff(counter))^2-n1^2); % we are overiding all the scanned values of Y1 and Y3 with the only few solutions % same as alpha in Chuang's texbook "Physics of Photonic Devices"
                Y3(counter) = k0*sqrt((neff(counter))^2-n3^2); % same as alpha2 in Chuang's textbook
                phi = -atan(Y1(counter)/Y2(counter)) + (counter-1)*pi;
                C1=sqrt(4*c*mu0/(neff(counter)*(t+1/Y1(counter)+1/Y3(counter))));

                Ey(counter,:) = ...
                    C1*(cos(phi)*exp(Y1(counter)*x)                          ) .* (x <= 0) + ...
                    C1*(cos(Y2(counter)*x+phi)                               ) .* (x > 0 & x < t) + ...
                    C1*(cos(Y2(counter)*t+phi)*exp(-Y3(counter)*(x-t))       ) .* (x >= t);
                Hx(counter,:) = -neff(counter)/(c*mu0)*Ey(counter,:);
                Hz(counter,:) = ...
                    -Y1(counter)/(1i*k0*c*mu0)*C1*(cos(phi)*exp(Y1(counter)*x)                          ) .* (x <= 0) + ...
                    Y2(counter)/(1i*k0*c*mu0)*C1*(sin(Y2(counter)*x+phi)                               ) .* (x > 0 & x < t) + ...
                    Y3(counter)/(1i*k0*c*mu0)*C1*(cos(Y2(counter)*t+phi)*exp(-Y3(counter)*(x-t))       ) .* (x >= t);
                
                Sz_TE(counter,:)=0.5*Ey(counter,:).*Hx(counter,:);
                
                phase_matrix(counter,:) = cos(k0*neff(counter).*z);  %note: all modes excited with the sample amplitude and phase.
            end
            
        end
        
    case {'TM'}
         for ii = 1:size(lambda,2)           %count for the number of wavelengths on the second dimension of lambda, as this is a row vector
            Y1 = k0(ii).*sqrt(neff.^2-n1^2);
            Y2 = k0(ii).*sqrt(n2^2-neff.^2);
            Y3 = k0(ii).*sqrt(neff.^2-n3^2);
            LHS=Y2.*t;          
            neff_fnd = nmax;                                
            q = 0;
            while neff_fnd > nmin
                Delta =-LHS-atan((n1/n2)^2*Y2./Y1)-atan((n3/n2)^2*Y2./Y3)+(q+1)*pi;
                Loc = find(abs(Delta) == min(abs(Delta))); % may not be accurate as sometimes due to computational round-off values may not be zero
                neff_fnd = neff(Loc);
                ls_neff(ii,q+1) = neff_fnd;
                q = q+1;
            end
        end
            
        neff=ls_neff; % just keep the actual neff, erase the old trial values of neff
        neff(neff<=nmin)=NaN;  % changes all the spurious neff which are not higher than nmin (max ncladding value) to NaN
        
        if dot(size(lambda),size(lambda)) == 2
            neff=neff(isfinite(neff)); %only keeps the finite values of neff (NaN values are discarded)
            number_of_roots = size(neff,2);
            a = k0*sqrt((min(neff))^2-nmin^2);
            %x=linspace(-1.5/(a*t),1.5/(a*t)+t,200);
            z=linspace(0,10*lambda/max(neff),200);
            Hy=zeros(number_of_roots,size(x,2));
            Hx = Hy; Hz = Hy; 
            Ex = Hy; Ey = Hy; Ez = Hy; 
            Y1=zeros(number_of_roots);
            Y2=zeros(number_of_roots);
            Y3=zeros(number_of_roots);
            counter = 1;
            for counter = 1:number_of_roots
                Y2(counter) = k0*sqrt(n2^2-(neff(counter)).^2);
                Y1(counter) = k0*sqrt((neff(counter))^2-n1^2); % we are overiding all the scanned values of Y1 and Y3 with the only few solutions
                Y3(counter) = k0*sqrt((neff(counter))^2-n3^2);
                phi = -atan(n2^2/n1^2*Y1(counter)/Y2(counter)) + (counter-1)*pi;
                C1=1;
                %C1=sqrt(4*c*miu0/(neff(counter)*(W+1/Y1(counter)+1/Y3(counter))));
                Hy(counter,:) = ...
                    C1*(cos(phi)*exp(Y1(counter)*x)                          ) .* (x <= 0) + ...
                    C1*(cos(Y2(counter)*x+phi)                               ) .* (x > 0 & x < t) + ...
                    C1*(cos(Y2(counter)*t+phi)*exp(-Y3(counter)*(x-t))       ) .* (x >= t);
                Ex(counter,:) = ...
                    (neff(counter)/(c*eps0*n1^2)*Hy(counter,:)                       ) .* (x <= 0) + ...
                    (neff(counter)/(c*eps0*n2^2)*Hy(counter,:)                       ) .* (x > 0 & x < t) + ...
                    (neff(counter)/(c*eps0*n3^2)*Hy(counter,:)                       ) .* (x >= t);
            
                Ez(counter,:) = ...
                    Y1(counter)/(1i*k0*c*eps0*n1^2)*C1*(cos(phi)*exp(Y1(counter)*x)                        ) .* (x <= 0) + ...
                    -Y2(counter)/(1i*k0*c*eps0*n2^2)*C1*(sin(Y2(counter)*x+phi)                            ) .* (x > 0 & x < t) + ...
                    -Y3(counter)/(1i*k0*c*eps0*n3^2)*C1*(cos(Y2(counter)*t+phi)*exp(-Y3(counter)*(x-t))     ) .* (x >= t);
            
                Sz_TM(counter,:)=0.5*Ex(counter,:).*Hy(counter,:);
                C1(counter,:)=sqrt(trapz(x,Sz_TM(counter,:))); %numerically evaluation of the normalization constant (approximate)
                
                %apply normalization constant to field and power density 
                Hy(counter,:)=Hy(counter,:)./C1(counter,:);
                Ex(counter,:)=Ex(counter,:)./C1(counter,:);
                Ez(counter,:)=Ez(counter,:)./C1(counter,:);
                Sz_TM(counter,:)=Sz_TM(counter,:)./(C1(counter,:).^2);
                      
                phase_matrix(counter,:) = cos(k0*neff(counter).*z);  %note: all modes excited with the sample amplitude and phase.
            end
%         H=Hy'*phase_matrix;
%         %H=(Hy(1,:))'*cos(k0*neff(1).*z)+(Hy(2,:))'*cos(k0*neff(2).*z); %assuming only two modes TODO change this to any number of modes
%         figure; surf(z,x,H); shading interp
%         xlabel('Distance z (micrometers)'); ylabel('Distance x (micrometers)'); zlabel('H_y (A/m)');
%         %H=(Hy(1,:))'*cos(k0*neff(1).*z)+(Hy(2,:))'*sin(k0*neff(2).*z); % different launch conditions
%         %figure; surf(z,x,H); shading interp    
        end
         
    case {OTHERWISE}
        ERROR_STATUS = 'Option not recognized. Exiting without calculating anything.';
        disp(ERROR_STATUS)
end

E.x = Ex; E.y = Ey; E.z= Ez; 
H.x = Hx; H.y = Hy; H.z =Hz;
