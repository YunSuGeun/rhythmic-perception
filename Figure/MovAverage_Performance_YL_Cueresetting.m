function [RESULTS_Behavior]=MovAverage_Performance_YL_Cueresetting(R,V,binning_param,Visi_start,Visi_End, Block_First,Block_Last,LR, LR_c)
if nargin<1
    error('You need to provide parameter');
end
if nargin<2
    V = 1;
end
if nargin<3
        binning_param.BINSIZE=Binsize; % [ms]
        binning_param.STEP=10; % [ms]
        binning_param.min_lat = 50; % Gabor presentation time with respect to movement onset [ms]
        binning_param.max_lat = 1500;
end
if nargin<4;Visi_start =1 ;end;  if nargin<5;Visi_End =8 ;end;  
if nargin<6;Block_First =1 ;end;  if nargin<7;Block_Last =6 ;end; 
if nargin<8; LR = 0;end; if nargin<9;LR_c = 0;end 
if LR ==1   % Target location = Right 
    Loc_T(1,1) = 1; Loc_T(1,2) = 2; 
    lr = 9;
elseif LR ==2 % Target location = Left
    Loc_T(1,1) = 2; Loc_T(1,2) = 3; 
    lr = 9;
elseif LR ==0 % Target location = Both
    Loc_T(1,1) = 1; Loc_T(1,2) = 3; 
    lr = 9;
    if size(R,2) < 9
        lr = 4;
    end 
end 
% if nargin>8;   % Cue location !!!! 
    lr = 9;
    lr_c =10; % cue_leftright

    for tr =1:size(R,1)
        if  R(tr,lr) ==1 && R(tr,4) == 1 % Target location == right & Valid
            R(tr,lr_c) = 1; % right
        elseif R(tr,lr) ==2 && R(tr,4) == 2 % Target location == left & invalid
            R(tr,lr_c) = 1; % Cue location = right
        elseif R(tr,lr) ==1 && R(tr,4) == 2 % Target location == right & invalid
            R(tr,lr_c) = 2; % Cue location = left
        elseif R(tr,lr) ==2 && R(tr,4) == 1 % Target location == left & Valid
            R(tr,lr_c) = 2; % Cue location = left
        end;
    end
    if LR_c ==1   % Cue location = Right 
        Loc_C(1,1) = 1; Loc_C(1,2) = 2;
        Loc_T(1,1) = 1; Loc_T(1,2) = 3; 
        LR =0;
%          disp('***Warning*** Target location is disregarded')
    elseif LR_c ==2 % Cue location = Left
        Loc_C(1,1) = 2; Loc_C(1,2) = 3;
        Loc_T(1,1) = 1; Loc_T(1,2) = 3; 
        LR =0;
%         disp('***Warning*** Target location is disregarded')
    elseif LR_c ==0  % Cue location = Both
        Loc_C(1,1) = 1; Loc_C(1,2) = 3;
%         disp('***Warning*** Cue location is disregarded')
    end
% end

% BINSIZE= input('Define Binsize :: ');
% STEP = input('Define moving step in ms :: ');
% min_lat = input('Define Min Lat in ms :: ');
% max_lat= input ('Define Max Lat in ms :: ');

Lat=binning_param.min_lat:binning_param.STEP:binning_param.max_lat;

Col_lat = 3;  % Timepoint
Col_resp = 2; % Acc 
Sacc = 6; 
Visi = 7;
%id_lat=[];
Vali_lat = [];
Inva_lat = [];
Nvali_lat = [];

Block = 8;
for i=1:length(Lat)
    if V <3 
        if nanmean(Lat) > 0 % Postcue
            id_lat{i}=find(R(:,Col_lat)>=Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)<=Lat(i)+binning_param.BINSIZE/2 & R(:,4) == V & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2)); % & R(:,Sacc)== 0 
        elseif nanmean(Lat) < 0 % Precue
            id_lat{i}=find(R(:,Col_lat)<=Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)>=Lat(i)+binning_param.BINSIZE/2 & R(:,4) == V & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2)); % & R(:,Sacc)== 0 
        elseif nanmean(Lat) == 0
            if abs(binning_param.BINSIZE) > 50 
                disp('Warning: You need to check BinSize!') 
            end
            if Lat(i) > 0 
                if binning_param.BINSIZE < 0 
                    binning_param.BINSIZE = binning_param.BINSIZE*(-1);
                elseif binning_param.BINSIZE > 0
                    binning_param.BINSIZE = binning_param.BINSIZE;
                end
                id_lat{i}=find(R(:,Col_lat)>=Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)<Lat(i)+binning_param.BINSIZE/2 & R(:,4) == V & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0  & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2) );
            elseif Lat(i) <= 0 
                if binning_param.BINSIZE > 0 
                    binning_param.BINSIZE = binning_param.BINSIZE*(-1);
                elseif binning_param.BINSIZE < 0
                    binning_param.BINSIZE = binning_param.BINSIZE;
                end
                id_lat{i}=find(R(:,Col_lat)<Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)>=Lat(i)+binning_param.BINSIZE/2 & R(:,4) == V & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0  & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2) );
            end
        end
        RESULTS_Behavior(i,1)=Lat(i); % center bin
        p=nanmean(R(id_lat{i},Col_resp));
        RESULTS_Behavior(i,2)=p*100; % percentage correct
        RESULTS_Behavior(i,3)= sqrt((p*(1-p))/length(id_lat{i}))*100; % SE
        RESULTS_Behavior(i,4)= length(id_lat{i}); % n trial 
        RESULTS_Behavior(i,5)= RESULTS_Behavior(i,2)-1.96*RESULTS_Behavior(i,3); % Inf limit 95% conf int
        RESULTS_Behavior(i,6)= RESULTS_Behavior(i,2)+1.96*RESULTS_Behavior(i,3); % Sup limit 95% conf int        
   %     RESULTS_Behavior(i,7)= nV;
    elseif V ==3 
        if nanmean(Lat) > 0 % Postcue
            Vali_lat{i}=find(R(:,Col_lat)>=Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)<Lat(i)+binning_param.BINSIZE/2 & R(:,4) == 1 & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0 & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2) );
            Inva_lat{i}=find(R(:,Col_lat)>=Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)<Lat(i)+binning_param.BINSIZE/2 & R(:,4) == 2 & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0 & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2));
        elseif nanmean(Lat) < 0 % Precue
            Vali_lat{i}=find(R(:,Col_lat)<Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)>=Lat(i)+binning_param.BINSIZE/2 & R(:,4) == 1 & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0  & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2));
            Inva_lat{i}=find(R(:,Col_lat)<Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)>=Lat(i)+binning_param.BINSIZE/2 & R(:,4) == 2 & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0  & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2));
        end
        RESULTS_Behavior(i,1)=Lat(i); % center bin
        pV=nanmean(R(Vali_lat{i},Col_resp));
        pI=nanmean(R(Inva_lat{i},Col_resp));
        p = pV - pI; 
        RESULTS_Behavior(i,2)=p*100; % percentage correct
        RESULTS_Behavior(i,3)= sqrt((p*(1-p))/length(Vali_lat{i}))*100; % SE
        RESULTS_Behavior(i,4)= length(Vali_lat{i}); % n trial 
        RESULTS_Behavior(i,5)= RESULTS_Behavior(i,2)-1.96*RESULTS_Behavior(i,3); % Inf limit 95% conf int
        RESULTS_Behavior(i,6)= RESULTS_Behavior(i,2)+1.96*RESULTS_Behavior(i,3); % Sup limit 95% conf int        
    elseif V ==4 
        if nanmean(Lat) > 0 % Postcue
            Nvali_lat{i}=find(R(:,Col_lat)>=Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)<Lat(i)+binning_param.BINSIZE/2 & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0 & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2) );
        elseif nanmean(Lat) < 0 % Precue
            Nvali_lat{i}=find(R(:,Col_lat)<Lat(i)-binning_param.BINSIZE/2 & R(:,Col_lat)>=Lat(i)+binning_param.BINSIZE/2 & R(:,5) == 0 & R(:,Visi) >= Visi_start & R(:,Visi) <= Visi_End & R(:,Block)>= Block_First & R(:,Block)<= Block_Last & R(:,Sacc)== 0 & R(:,lr) >= Loc_T(1,1)& R(:,lr) < Loc_T(1,2) & R(:,lr_c) >= Loc_C(1,1)& R(:,lr_c) < Loc_C(1,2));
        end
        RESULTS_Behavior(i,1)=Lat(i); % center bin
        p=nanmean(R(Nvali_lat{i},Col_resp));
        RESULTS_Behavior(i,2)=p*100; % percentage correct
        RESULTS_Behavior(i,3)= sqrt((p*(1-p))/length(Nvali_lat{i}))*100; % SE
        RESULTS_Behavior(i,4)= length(Nvali_lat{i}); % n trial 
        RESULTS_Behavior(i,5)= RESULTS_Behavior(i,2)-1.96*RESULTS_Behavior(i,3); % Inf limit 95% conf int
        RESULTS_Behavior(i,6)= RESULTS_Behavior(i,2)+1.96*RESULTS_Behavior(i,3); % Sup limit 95% conf int          
    end
end
    
