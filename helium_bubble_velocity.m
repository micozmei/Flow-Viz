clear all; close all; clc;

%%Input
film_thickness =    500/(10^9);%m
bubble_diameter =   (1/1000):(0.001/1000):(5/1000);%m
freestream_velocity = 15;%m/s
chord_length = 24/12*0.3048;%m

%%Knowns
helium_density =    0.164;%kg/m^3
air_density =       1.225;%kg/m^3
soap_density =      932;%kg/m^3
g =                 9.81;%m/s^2
air_viscosity =     1.81*10^(-5);%kg(m*s)
dynamic_viscosity = air_viscosity;

%%Loop
bubbles = length(bubble_diameter);
helium_mass = zeros(bubbles,1);
soap_mass = helium_mass;
total_mass = helium_mass;
total_density = helium_mass;
weight = helium_mass;
drag_coefficient = helium_mass;
terminal_velocity = helium_mass;

for n = 1:bubbles
    b_rad = bubble_diameter(n)/2;
    helium_mass(n) = 4*pi/3*(b_rad-film_thickness)^3*(helium_density);
    soap_mass(n) = 4*pi/3*((b_rad)^3-(b_rad-film_thickness)^3)*(soap_density);
    total_mass(n) = soap_mass(n)+helium_mass(n);
    total_density(n) = total_mass(n)/(4*pi/3*b_rad^3);
    weight(n) = -(4*pi/3*b_rad^3*(total_density(n)-air_density)*g);
    drag_coefficient(n) = 6*pi*air_viscosity*b_rad;
    terminal_velocity(n) = weight(n)/drag_coefficient(n);
    stokes_number(n) = (total_density(n)*bubble_diameter(n)^2/(18*dynamic_viscosity)*freestream_velocity/chord_length);
end

figure

subplot(2,2,1);
plot(bubble_diameter*1000,weight);
xlabel diameter(mm)
ylabel 'buoyant/weight force (N)'
axis([1 5 -.1*10^-6 .4*10^-6]);

subplot(2,2,2);
plot(bubble_diameter*1000,drag_coefficient);
xlabel diameter(mm)
ylabel c_d
axis([1 5 0 1*10^-6]);

subplot(2,2,3);
plot(bubble_diameter*1000,abs(terminal_velocity));
xlabel diameter(mm)
ylabel V_t_e_r_m_i_n_a_l(m/s)
axis([1 5 0 .5]);

subplot(2,2,4);
plot(bubble_diameter*1000,(stokes_number));
xlabel diameter(mm)
ylabel 'Stokes Number'
axis([1 5 0 1.5]);

[v,n] = min(abs(terminal_velocity)); 
txt = ['neutrally buoyant bubble diameter = ' num2str(bubble_diameter(n)*1000) ' mm'];
disp(txt);
txt = ['Stokes number for neutrally buoyant bubble = ' num2str(stokes_number(n))];
disp(txt);
txt = ['Density = ' num2str(total_density(n))];
disp(txt);