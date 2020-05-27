load('Kymographs.mat')
load('t0SummaryStats_continuityEqn.mat')
%% prepping data
rho = zeros(139,60);

%select large tissues to find average flow fields
selection=(areaMMt0 > 2.7 & densityt0 > 2350 & densityt0 < 3050);

%alternatively, select small tissues
%selection=(areaMMt0 < 2.7 & densityt0 > 2350 & densityt0 < 3050);

%find mean radial velocity kymograph
radVelKymos = radVelKymoFromCenter(:,:,selection);
radialVelocity = nanmean(radVelKymos,3);

%output will be a density kymograph
rho(1,:)=radialVelocity(2,:);
rho(1,~isnan(rho(1,:)))=2700*10^-6;
rho(1,isnan(rho(1,:)))=0;

radialVelocity(:,1)=0; %radial velocity of the tissue center is by definition 0
radialVelocity(isnan(radialVelocity))=0; %convert nans to 0 for simulation

%% Forward Euler


imsize=60;
imtime=139;

deltaT=0.3333*139/imtime; %in hours
deltaR = 58.4*60/imsize; %in microns
ri_plus = (0.5:1:imsize-1)*deltaR; %in microns
ri_minus = [0,ri_plus(1:end-1)];
k=(2^(1/16)-1);

Ai = pi*(ri_plus.^2-ri_minus.^2);

radialVelocityScaled = radialVelocity(2:end,:);
radialVelocityScaled=imresize(radialVelocityScaled,[imtime,imsize]);


for ii = 1:size(radialVelocityScaled,1)
    D=800;
    rho_plus=(rho(ii,2:end)+rho(ii,1:end-1))/2;
    rho_minus=[0, rho_plus(1:end-1)];
    d_rho_plus = (rho(ii,2:end)-rho(ii,1:end-1))/deltaR;
    d_rho_minus = [0, d_rho_plus(1:end-1)];
    v_plus = (radialVelocityScaled(ii,2:end)+radialVelocityScaled(ii,1:end-1))/2;
    v_minus = [0, v_plus(1:end-1)];
    
    %comment for only proliferation
     rho(ii+1,1:end-1)=rho(ii,1:end-1)+deltaT*(2*pi*(-rho_plus.*v_plus.*ri_plus+d_rho_plus*D.*ri_plus+...
        rho_minus.*v_minus.*ri_minus-d_rho_minus*D.*ri_minus)./Ai+k*rho(ii,1:end-1));
end

imagesc(rho*10^6)
caxis([0,6000])
colormap(cmapViridis)
colorbar
