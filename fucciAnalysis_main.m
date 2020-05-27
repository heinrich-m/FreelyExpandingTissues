
%set thresholds manually
red_thres = 50;
green_thres = 50;


%copy file paths
mask_stack_path = '';
gfp_stack_path = '';
rfp_stack_path = '';

dark_out_path = '';
red_out_path = '';
green_out_path = '';
yellow_out_path = '';

mask_tiff_info = imfinfo(mask_stack_path); 
gfp_tiff_info = imfinfo(gfp_stack_path); 
rfp_tiff_info = imfinfo(rfp_stack_path); 
mask_tiff_stack = imread(mask_stack_path, 1) ; % read in first image
gfp_tiff_stack = imread(gfp_stack_path, 1) ; % read in first image
rfp_tiff_stack = imread(rfp_stack_path, 1) ; % read in first image

% Process first images 
[dark_out_stack, gfp_out_stack, rfp_out_stack, yellow_out_stack] = process_fucci_with_rgyd(mask_tiff_stack, gfp_tiff_stack, rfp_tiff_stack, red_thres, green_thres);

%concatenate each successive tiff to tiff_stack
for ii = 2 : size(mask_tiff_info, 1)
    mask_temp_tiff = imread(mask_stack_path, ii);
    %mask_tiff_stack = cat(3 , mask_tiff_stack, mask_temp_tiff);
    
    gfp_temp_tiff = imread(gfp_stack_path, ii);
    %gfp_tiff_stack = cat(3 , gfp_tiff_stack, gfp_temp_tiff);
    rfp_temp_tiff = imread(rfp_stack_path, ii);
    %rfp_tiff_stack = cat(3 , rfp_tiff_stack, rfp_temp_tiff);
    
    %[gfp_out_temp, rfp_out_temp] = process_fucci_with_mask(mask_temp_tiff, gfp_temp_tiff, rfp_temp_tiff, low_thres);
    [dark_out_temp, gfp_out_temp, rfp_out_temp, yellow_out_temp] = process_fucci_with_rgyd(mask_temp_tiff, gfp_temp_tiff, rfp_temp_tiff, red_thres, green_thres);

    gfp_out_stack = cat(3 , gfp_out_stack, gfp_out_temp);
    rfp_out_stack = cat(3 , rfp_out_stack, rfp_out_temp);
    dark_out_stack = cat(3 , dark_out_stack, dark_out_temp);
    yellow_out_stack = cat(3 , yellow_out_stack, yellow_out_temp);
    
    
end

imwrite(gfp_out_stack(:,:,1), gfp_out_path, 'tiff', 'Compression','none')
imwrite(rfp_out_stack(:,:,1), rfp_out_path, 'tiff', 'Compression','none')
imwrite(dark_out_stack(:,:,1), dark_out_path, 'tiff', 'Compression','none')
imwrite(yellow_out_stack(:,:,1), yellow_out_path, 'tiff', 'Compression','none')

for ii = 2 : size(mask_tiff_info, 1)
    imwrite(gfp_out_stack(:,:,ii) , gfp_out_path , 'WriteMode' , 'append', 'Compression','none') ;
    imwrite(rfp_out_stack(:,:,ii) , rfp_out_path , 'WriteMode' , 'append', 'Compression','none') ;
    imwrite(dark_out_stack(:,:,ii) , dark_out_path , 'WriteMode' , 'append', 'Compression','none') ;
    imwrite(yellow_out_stack(:,:,ii) , yellow_out_path , 'WriteMode' , 'append', 'Compression','none') ;
end


