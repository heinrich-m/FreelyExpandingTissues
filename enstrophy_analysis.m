% load PIV data, which includes vorticity
load('PIV_output.mat')
%%
vorticityZeros=cell(size(vorticity));
for i=1:length(vorticity)
    
vorticityZeros{i}=vorticity{i};
vorticityZeros{i}(isnan(vorticityZeros{i}))=0;
end

%%
SpectrumVorticity=cell(140,1);

%outside loop is for every tissue
for i=1:length(vorticityZeros)
    i
    %inside loop is for every timepoint for each tissue
    for t=1:size(vorticityZeros{i},3)
        %choose one tissue
        thisVorticity=vorticityZeros{i}(:,:,t);
        %pad the vortex with zeros so that fourier analysis has higher
        %resolution
        vorticityPadded=zeros(500);
        vorticityPadded(1:119,1:119)=thisVorticity;
        thisVorticity=vorticityPadded;
        
        %take 2D fft of the vorticity data
        %see https://www.mathworks.com/help/matlab/ref/fft2.html
        spectra=fft2(thisVorticity);
        spectrashift=fftshift(spectra);

        %the modulus of fourier components squared gives the enstrophy
        spectrumVorticity{i}(:,:,t)=abs(spectrashift).^2;

    end
end

