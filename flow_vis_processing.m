%Flow-vis processing
clear all; close all; clc
steady = 1;
transient = 2;

%% Inputs
vname = 'steady off to steady on 2.mp4';
suffix = 'transient';
movie_name = 'activation steady69.avi';
save_steps = 0;

bubble_threshold = 0.075;
big_bubble_filter = 1.1;
bubble_intensity = 80;

black_thresh = 30;
white_thresh = 0.75;

di_color = 0;
turn_point = 242;
frame_start = 1;
frame_override = 0;

mode = steady;
color_replace = 1;
color_range = 0.25;
color_power = 1;

movie_mode = 1;
frame_rate = 24;
fade_rate = 0.3*bubble_intensity/frame_rate;

%% Notes
% steady on to steady off:
% DRS finishes deactivation on frame 586

% steady off to steady on:
% DRS activation starts at 532
% DRS activation ends at 550

% steady off to steady on 2:
% DRS activation starts at 242
% DRS activation ends at 260

% DRS activation 2
% DRS (de-activation) starts at frame 12, and ends at frame 31

%% Load Video
v = VideoReader(vname);
video = read(v);
vid_size = size(video);
scale = 1;
if frame_override == 0
    frames = vid_size(4);
else
    frames = frame_override;    
end

width = vid_size(1)*scale;
height = vid_size(2)*scale;
frame = cell(frames,1);

if scale == 1
    progressbar('save frames','subtract and gray','binarize','composition');
    for n = frame_start:frames
        %disp(['resize ' num2str(n)]);
        progressbar((n-frame_start)/(frames-frame_start),0,0,0);
        frame{n} = video(:,:,:,n);
    end
else
    progressbar('resize','subtract and gray','binarize','composition');
    for n = frame_start:frames
        %disp(['resize ' num2str(n)]);
        progressbar((n-frame_start)/(frames-frame_start),0,0,0);
        frame{n} = imresize(video(:,:,:,n),scale);
    end
end

p_frame = frame;
clear video
clear v

if movie_mode == 1
outputVideo = VideoWriter(movie_name);
outputVideo.FrameRate = frame_rate;
open(outputVideo)
end

%% Subtract wing and background from images,
base_frame = p_frame{frame_start};
progressbar('subtract and gray','binarize','composition');
for n = frame_start:frames
    %disp(['subtract ' num2str(n)]);
    progressbar((n-frame_start)/(frames-frame_start),0,0);
    p_frame{n} = rgb2gray(p_frame{n}-base_frame);
end

if save_steps == 1
    copy1 = base_frame;
    copy2 = p_frame{100};
    fname = ['base_frame.png'];
    imwrite(copy1,fname);
    fname = ['subtracted_frame.png'];
    imwrite(copy2,fname);
end

%% Binarize
progressbar('binarize','composition');
for n = frame_start:frames
    %disp(['bw ' num2str(n)]);
    progressbar((n-frame_start)/(frames-frame_start),0);
    t_frame = uint8(imbinarize(p_frame{n},bubble_threshold));
    p_frame{n}= uint8(t_frame - uint8(imbinarize(p_frame{n},big_bubble_filter)));
end

%% Create Composite Image
composite_image = uint8(zeros(width,height,3));
progressbar('composition');
if mode == steady
    for n = frame_start:frames
        %disp(['composite ' num2str(n)]);
        composite_image(:,:,1) = uint8(double(composite_image(:,:,1)) + double(p_frame{n})*bubble_intensity);
        composite_image(:,:,2) = uint8(double(composite_image(:,:,2)) + double(p_frame{n})*bubble_intensity);
        composite_image(:,:,3) = uint8(double(composite_image(:,:,3)) + double(p_frame{n})*bubble_intensity);
        progressbar((n-frame_start)/(frames-frame_start));
        if movie_mode == 1
            base_comp = composite_image;
            composite_image(:,:,1) = composite_image(:,:,1) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
            composite_image(:,:,2) = composite_image(:,:,2) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
            composite_image(:,:,3) = composite_image(:,:,3) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
            composite_image = uint8(double(composite_image)-ones(width,height,3)*fade_rate);
            %imshow(imresize(composite_image,0.75));
            overlay = frame{n};
            overlay(:,:,color_replace) = composite_image(:,:,color_replace);
            writeVideo(outputVideo,overlay)
        end
    end
end

if save_steps == 1
    fname = ['binarized frame.png'];
    imwrite(p_frame{100}*255,fname);
    fname = ['composite_frame.png'];
    imwrite(composite_image,fname);
end

%Transient
if mode == transient   
    for n = frame_start:frames
        %disp(['composite ' num2str(n)]);
        frac = (n-frame_start)/(frames-frame_start);
        if turn_point == 0 || di_color == 0
        angle = frac*color_range;
        cv = hsv2rgb([angle 1 1]);
        elseif di_color == 1
            if n > turn_point
                cv = [0 1 0];
            else
                cv = [1 0 0];
            end
        end
        
        composite_image(:,:,1) = uint8(double(composite_image(:,:,1)) + double(p_frame{n})*bubble_intensity*cv(1)^color_power);
        composite_image(:,:,2) = uint8(double(composite_image(:,:,2)) + double(p_frame{n})*bubble_intensity*cv(2)^color_power);
        composite_image(:,:,3) = uint8(double(composite_image(:,:,3)) + double(p_frame{n})*bubble_intensity*cv(3)^color_power);
        progressbar((n-frame_start)/(frames-frame_start));
        
        if movie_mode == 1
            base_comp = composite_image;
            composite_image(:,:,1) = composite_image(:,:,1) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
            composite_image(:,:,2) = composite_image(:,:,2) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
            composite_image(:,:,3) = composite_image(:,:,3) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
            composite_image = uint8(double(composite_image)-ones(width,height,3)*fade_rate);
            %imshow(imresize(composite_image,0.75));
            writeVideo(outputVideo,composite_image+frame{n})
        end
    end
end

%% Cleanup
%Remove erroneous spots from shaking
base_comp = composite_image;
composite_image(:,:,1) = composite_image(:,:,1) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
composite_image(:,:,2) = composite_image(:,:,2) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));
composite_image(:,:,3) = composite_image(:,:,3) - 255*uint8(imbinarize(rgb2gray(base_comp),white_thresh));

%% Overlay on base_image
overlay = base_frame;

%Color Replace
if mode == steady
    overlay(:,:,color_replace) = composite_image(:,:,color_replace);
else
    overlay = overlay + composite_image;
end
figure
image(overlay);

%% Save images
if movie_mode == 1
    close(outputVideo)
end
fname = [vname '-' suffix '-composite_image.png'];
imwrite(composite_image,fname);
fname = [vname '-' suffix '-overlayed_image.png'];
imwrite(overlay,fname);