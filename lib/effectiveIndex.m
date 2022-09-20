lambda_0 = 1.55;
h = 0.22;   %Si layer thikness
w = 0.50;   %Waveguide width
n_clad = 1.446; %Refractive index of cladding
n_core = 3.487; %Refractive index of the core
n_subs = 1.446; %Refractive index of the substrate
polarization = 'TM';

%% Calculation of the effective index of the vertical slab problem 
    d = h; n1=n_clad; n2 = n_core; n3 = n_subs;
    if(strcmp('TE',polarization)), pol = 'TE'; else, pol = 'TM'; end
    y=linspace(-2*h,3*h,1000);
    [ne,Ev,Hv] = asym_slab(lambda_0,n1,n2,n3,d,pol,y);

%% Calculation of the wave effective index (from the horizontal analysis) only for the fundamental vertical mode
    d = w; n1 = n_clad; n2 = ne(1); n3=n_clad;
    if(strcmp('TE',polarization)), pol = 'TM'; else, pol = 'TE'; end
    x=linspace(-2*w,3*w,1000);
    [ne,Et,Hh] = asym_slab(lambda_0,n1,n2,n3,d,pol,x); %symmetric air bounded slab
    
 % Computation of fields   
    
    for i = 1:length(ne)
        Eh.x = -Et.y(i,:); Eh.y = Et.x(i,:); Eh.z = Et.z(i,:);
        
        if(strcmp('TE',polarization))
           F = meshgrid(Ev.y,1:length(Ev.y))';
           G = meshgrid(Eh.y,1:length(Eh.y));
        else
           F = meshgrid(Ev.x,1:length(Ev.x))';
           G = meshgrid(Eh.x,1:length(Eh.x));
        end
        
        E = F.*G;
        
        %Calculation of the confinement factor for the first waveguide.
        Ein = E(x<w,y<h); x_in = x(x<w); y_in = y(y<h);
        Ein = Ein(x_in>0,y_in>0);%Stores the field inside the waveguide
        Iin = sum((Ein(:).^2)); Iall = sum((E(:).^2));
        gamma = Iin/Iall; 
        
        figure(1); 
        subplot(1,length(ne),i); pcolor(x,y,E.^2); shading interp; 
        if(strcmp('TE',polarization))
            title(strcat('|Ey|^2 for ne=',num2str(ne(i)),' and \Gamma = ',num2str(gamma)));
        else
            title(strcat('|Ex|^2 for ne=',num2str(ne(i)),' and \Gamma = ',num2str(gamma)));
        end
        colormap hot
 
    end
