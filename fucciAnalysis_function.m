function [dark_out, gfp_out, rfp_out, yellow_out] = process_fucci_with_rgyd(mask_img, gfp_img, rfp_img, red_thres, green_thres)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% function process_fucci_with_mask: 
    % This function takes in 8-bit images of the same size. 
    % mask_img_path is the 8-bit nuclei segmentation mask of all
    % nuclei.
    % gfp_img_path is the 8-bit (background subtracted, rescaled) GFP
    % image.
    % rfp_img_path is the 8-bit (background subtracted, rescaled) RFP
    % image.
    % red_thres, green_thres gives the upper bound below which red/green intensity
    % comparisons should be ignored. 

    % The function uses the mask to find all regions given by mask, and
    % compare red/green average intensity values in these blobs. 
    % The output is an image of the same size as the input images, with
    % absolute red/green values in each mask location. 
    % In this case, each channel has a threshold to determine if it's on or
    % off; both on indicates a yellow cell. 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Read in the images from input paths  
    %mask_img = imread(mask_img_path);
    BW = imcomplement(mask_img);         % inverse the mask so that 255 is "on"
    %gfp_img = imread(gfp_img_path);
    %rfp_img = imread(rfp_img_path);
    
    %% Determine the connected components in the mask regions:
    CC = bwconncomp(BW);
    cc_num = CC.NumObjects;    % Number of connected regions in mask 
      
    % Get region properties for each connected region:
    S = regionprops(CC, 'PixelIdxList');
    
    dark_out = false(size(BW, 1), size(BW, 2)); % Allocate blank image for dark cells
    gfp_out = false(size(BW, 1), size(BW, 2)); % Allocate blank image for gfp
    rfp_out = false(size(BW, 1), size(BW, 2)); % Allocate blank image for rfp
    yellow_out = false(size(BW, 1), size(BW, 2)); % Allocate blank image for yellow cells (both on)

    %% Loop over each connected region
    for i=1:cc_num
        % Get associated pixel indices for that region
        idx = S(i).PixelIdxList;
        
        % Get mean intensity values in GFP, RFP at same pixel locations. 
        gfp_list = gfp_img(idx);
        rfp_list = rfp_img(idx);
        gfp_med = median(gfp_list);
        rfp_med = median(rfp_list);
            
        % If GFP, RFP intensities are both below threshold, do nothing. 
        if(gfp_med < green_thres && rfp_med < red_thres)
            dark_out(idx) = true; 
        end
        % Otherwise, compare red/green signals and set higher to "on". 
        if(gfp_med >= green_thres && rfp_med < red_thres)
            % Turn green spaces on
            gfp_out(idx) = true; 
        end
        if(gfp_med < green_thres && rfp_med >= red_thres)
            % Turn red spaces on
            rfp_out(idx) = true; 
        end
        if(gfp_med >= green_thres && rfp_med >= red_thres)
            yellow_out(idx) = true; 
        end       
    end
end