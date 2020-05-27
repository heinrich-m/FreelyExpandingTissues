%Calculates area changes of many mask tif stacks in a folder. You can have
%other tif stacks in this folder as well, just make sure you uniquely
%identify the mask stacks in the name. _mask is fine.

saveName='New_Dynamics_20191022.mat';
directory=pwd(); %directory containing the images you want to analyze

leaderCellSep=0.1;
binAmount=1; %is your data scaled at all? Best practice is to leave it untouched
pixelSize=1.825/1000; %here, pixel size is in millimeters
framesPerHour=3; %frame rate of your tif stack

%pull out all of the tif stacks that refer to mask files you want to
%analyze
maskContains='*_mask*.tif'; %*.bmp or *.tif or *.jpg or *.tiff or *.jpeg
maskDirec=dir([directory,filesep,maskContains]); maskFilenames={};
[maskFilenames{1:length(maskDirec),1}] = deal(maskDirec.name);
maskFilenames = sortrows(maskFilenames); %sort all image files


    %% Analysis loop:
    

numberOfStacks=length(maskFilenames)

%many options for different statistics to calculate on the masks
areaMM=cell(numberOfStacks,1);
areaPercentChange=areaMM;
perimeterMM=areaMM;
radiusMM=areaMM;
majorAxisMM=areaMM;
minorAxisMM=areaMM;
aspectRatio=areaMM;
edgeSmoothness=areaMM;
circularity=areaMM;
effectiveVelocity=areaMM;
radiusChangeMM=areaMM;
minorAxisChangeMM=areaMM;
majorAxisChangeMM=areaMM;
minorAxisEffectiveVelocity=areaMM;
majorAxisEffectiveVelocity=areaMM;

meanDistMean=areaMM;
stdDistMean=areaMM;
meanDistMeanSpeed=areaMM;
meanDistSpeed=areaMM;

meanDist=areaMM;
stdDist=areaMM;



for stackFile=1:1:numberOfStacks 

    amount=length(imfinfo(fullfile(directory,maskFilenames{stackFile})));%number of mask files in folder
    for i=1:1:amount

        image=logical(imread(fullfile(directory, maskFilenames{stackFile}),i)); % read image, and make sure it is binary
        thisBlob = regionprops(image, 'Area', 'Extrema', 'MajorAxisLength','MinorAxisLength','Perimeter','EquivDiameter')  ;
        %regionprops is the classical matlab blob analysis function. Lots
        %of useful outputs including areas
        
        %save important statistics for this time point
        areaMM{stackFile}(i)=thisBlob.Area*pixelSize^2*binAmount^2; %area in millimeters
        areaPercentChange{stackFile}(i)=areaMM{stackFile}(i)/areaMM{stackFile}(1)-1;
        perimeterMM{stackFile}(i)=thisBlob.Perimeter*pixelSize*binAmount;
        radiusMM{stackFile}(i)=thisBlob.EquivDiameter/2*pixelSize*binAmount;
        majorAxisMM{stackFile}(i)=thisBlob.MajorAxisLength*pixelSize*binAmount;
        minorAxisMM{stackFile}(i)=thisBlob.MinorAxisLength*pixelSize*binAmount;
        aspectRatio{stackFile}(i)=majorAxisMM{stackFile}(i)/minorAxisMM{stackFile}(i);
        edgeSmoothness{stackFile}(i)=2*pi*radiusMM{stackFile}(i)/perimeterMM{stackFile}(i);
        circularity{stackFile}(i)=4*pi*areaMM{stackFile}(i)/(perimeterMM{stackFile}(i))^2;
        
        if i>1
            effectiveVelocity{stackFile}(i-1)=(radiusMM{stackFile}(i)-radiusMM{stackFile}(i-1))*framesPerHour*1000; %effective velocity in microns/hr if you have circles
            effectiveVelocity{stackFile}(i-1)=(radiusMM{stackFile}(i)-radiusMM{stackFile}(i-1))*framesPerHour*1000;
        end
    end
end
filetokens=strtok(maskFilenames,'_');
clearvars -except directory filetokens minorAxisEffectiveVelocity majorAxisEffectiveVelocity radiusChangeMM...
     areaMM areaPercentChange perimeterMM radiusMM majorAxisMM minorAxisMM aspectRatio edgeSmoothness...
     circularity effectiveVelocity minorAxisChangeMM majorAxisChangeMM saveName


save(saveName);
% disp('DONE.')