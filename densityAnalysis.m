
%set minimum and maximum areas for nuclei
blobMinimum=16;
blobMaximum=450;


inputDataScale=1.4; %scale of nuclei image relative to PIV image
calculateDensity=1; %1 if calculation of density is desired
densityBoxSize=64; %box size in pixels for counting nuclei
overlapScale=32; %overlap in pixels of nuclei counting boxes
pixelSize=1.825; %in microns

saveName='density20191022.mat';
inputDirectory=pwd(); %directory containing the images you want to analyze

%directory for masks
maskDirectory='\\latrobe\CohenLabArchive\Cutter Methods Paper\FreelyExpandingTissues\data for analysis\masks';

inputContains='*_JV.tif'; 
inputDirec=dir([inputDirectory,filesep,inputContains]); inputFilenames={};
[inputFilenames{1:length(inputDirec),1}] = deal(inputDirec.name);
inputFilenames = sortrows(inputFilenames); %sort all image files

filetokens=strtok(inputFilenames,'_')
%% Analysis Loop
numberOfStacks=length(inputFilenames);

%we will calculate local density (cells/area), local cell counts, as well
%as counts for the entire tissue
density=cell(1,numberOfStacks);
localCount=cell(1,numberOfStacks);
totalCells=cell(1,numberOfStacks);

for stackFile=1:numberOfStacks
    amount=length(imfinfo(fullfile(inputDirectory,inputFilenames{stackFile})));
    
    
    %determine the size of the input files (assumes square images)
    sliceSize=size(imread(fullfile(inputDirectory,inputFilenames{stackFile}),1))/inputDataScale;
    
    %determine the final size of the data, given the window size and
    %overlap
    finalSize=round((sliceSize-densityBoxSize)/overlapScale)+1;
    
    %predefine density and local count variables with nan's
    density{stackFile}=nan([finalSize,amount]);
    localCount{stackFile}=nan([finalSize,amount]);
    
    
    for imageSlice=1:1:amount
        
        fprintf([num2str(imageSlice),'/', num2str(amount),', stack #:',num2str(stackFile), '\n']);

        %load in the binary nuclei files
        BW=imread(fullfile(inputDirectory,inputFilenames{stackFile}),imageSlice);
        if islogical(BW)~=1
            BW=imread(fullfile(inputDirectory,inputFilenames{stackFile}),imageSlice)<127;
        end
        
        %locate the masks
        maskContains='*_mask.tif';
        maskDirec=dir([maskDirectory,filesep,['*', filetokens{stackFile},'*']]); maskFilenames={};
        [maskFilenames{1:length(maskDirec),1}] = deal(maskDirec.name);
        maskFilenames = sortrows(maskFilenames);
        
        %load in the masks
        mask=imread(fullfile(maskDirectory,maskFilenames{1}),imageSlice);
        scaledMask=imresize(mask,inputDataScale);
        
        %erode masks to account for "over-segmenting"
        erodedScaledMask=bwdist(~scaledMask)>9;
        erodedMask=imresize(erodedScaledMask,sliceSize);
        BW(erodedScaledMask==0)=0;
        
        %filter out nuclei outside the expected size range
        BWfilt=bwareafilt(BW,[blobMinimum blobMaximum]);
        
        %locate the centroids of all connected blobs
        theseBlobs = regionprops(BWfilt,'Centroid');
        
        theseCentroids=cat(1,theseBlobs.Centroid);
        
        %find centroid locations in phase data units
        xCentroids=theseCentroids(:,1)/inputDataScale;
        yCentroids=theseCentroids(:,2)/inputDataScale;
        
        
        icounter=1;
        
        %record the total number of cells in the tissue for this time point
        totalCells{stackFile}(imageSlice)=length(xCentroids);
        if calculateDensity==1
            
            %loop in the x (i) and y (j) direction with analysis window
            for i =1:overlapScale:sliceSize(2)-densityBoxSize+1 %
                jcounter=1;
                for j=1:overlapScale:sliceSize(1)-densityBoxSize+1
                    if erodedMask(round(j+densityBoxSize/2),round(i+densityBoxSize/2))>0.001
                        inX=xCentroids>i & xCentroids<i+densityBoxSize-1;
                        inY=yCentroids>j & yCentroids<j+densityBoxSize-1;
                        
                        %inBoth will be true if the cell nucleus is within
                        %the analysis window
                        inBoth=inX & inY;
                        
                        cellCountInBox=sum(inBoth);
                        
                        %mask density gives the area of the tissue within
                        %the given analysis window. This is important for
                        %not underestimating density at the edge of the
                        %tissue
                        maskDensity= sum(sum(erodedMask(j:j+densityBoxSize-1, i:i+densityBoxSize-1)));
                        thisDensity=cellCountInBox/maskDensity/pixelSize^2*10^6;
                        if thisDensity>0
                            %record density and local count if there are
                            %cells there. If not, leave as NaN
                            density{stackFile}(jcounter,icounter,imageSlice)=thisDensity;
                            localCount{stackFile}(jcounter,icounter,imageSlice)=cellCountInBox;
                        end
                    end
                    jcounter=jcounter+1;
                end
                icounter=icounter+1;
            end
            
        end
        
        
    end
   
    
    
end


clearvars -except filetokens density totalCells localCount saveName
save(saveName)