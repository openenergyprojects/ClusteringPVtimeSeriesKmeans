%% readPV power production from xls file 
%Reshape the data into a matrix format where columns are the power production per day
close all;
clear all;
clc;
%import the PV power production form an excel file 

a=importdata('PVYToffis201617.csv');

%% for the moment we will ignor the timestamp:
%we need to add the 10 min interval to each date
t=datetime(a.textdata,'InputFormat','dd/MM/yyyy');

%for the moment the time within a day is generated separately
tDay=1:24/150:24;% to simulate 144 recodings in 24h (every 10 min): 24hx6rec=144 points;

%Process data to account for missing numbers/cells
%replace empty cells with 0 (in .xls or .csv file the hours where there is 0 production were stored as null values)
k = find(isnan(a.data))'; 
a.data(k) = 0;
% and
a.data(isnan(a.data)) = 0;

%reshape the input annual data into 365 daily curves stored in the columns
%of the matrix AnualPpv
AnualPpv=reshape(a.data(1:144*365),144,365);
figure(1);
for k=1:1:365
plot(tDay,AnualPpv(:,k))
hold on
end
hold off
title 'Daily PV output Cyprus site from june 2016 to june 2017'
xlabel 'time (h)'
ylabel 'PV output (W)'
%% K-mean for clustering data
noOfClusters=3;

AnualPpvUseful=AnualPpv(35:125,:);%limit the clustering to the util data to eliminate outliers like 0 production during nighttime
X=AnualPpvUseful'; %transpose the matrix such that k-means looks at similarities between 
[IDX,C] = kmeans(X, noOfClusters, 'start','uniform', 'emptyaction','singleton');
fprintf('clusters statistical evaluation:');
tabulate(IDX)
tbl=tabulate(IDX);
 figure (2)
 x_time= [6:1/6:21]; %useful time hours for solar;
 plot(x_time, C(1,:), x_time, C(2,:),x_time, C(3,:));
%  h=[];
%  stringLegend='';
%  q = char(39);
%  strLegend=[];
%  for i=1:length(tbl(:,1))
%      plot(C(i,:));
%       strLegend=[strLegend, strcat(q,num2str(tbl(i,3)),'%',q)];
%      hold on;
%  end
%    hold off
 xlabel 'time (h)'
 ylabel 'PV out (W)'
legend (strcat(num2str(tbl(1,2)),'daysPerYear'), strcat(num2str(tbl(2,2)),'daysPerYear'), strcat(num2str(tbl(3,2)),'daysPerYear'));
title '# clusters PVout (W) in Cyprus'
probabilityWeightsPVClusters=tbl(:,3)/100; %Rates in percentage from the number of days in a year;
w=probabilityWeightsPVClusters;
fprintf('SannityCheck: The sum of the probability weights shall be 1\n')
if sum(w)<=1.001 && sum(w)>=0.999
    fprintf('Sanity Check OK')
else 
    fprintf ('Sanilty check Error!! See if data is well defined')
end
ClusterDaysPerYear=tbl(:,2) %days per year for each cluster

%
%% Statistics
%main feature of the centroids is to have similar energy produced within the day 
%this feature is calculated as the area under the plot. 
%we do this using the trapezoid integral method from Matlab
% %  Area = trapz(X,Y) computes the integral of Y with respect to X using
% %     the trapezoidal method.  X and Y must be vectors of the same
% %     length, or X must be a column vector and Y an array whose first
% %     non-singleton dimension is length(X).  trapz operates along this
% %     dimension.
DailyEnPV=[]; %vector stoting the PV daily energy production
for k=1:1:365
PVEnDD=trapz(AnualPpv(:,k))/6;
%we devide by 6 becaue we have the data measured at 10 min intervals
% and we would like to measure the energy in W/h
DailyEnPV=[DailyEnPV,PVEnDD];
end
 figure (3);
 scatter(1:length(DailyEnPV), DailyEnPV);
 title 'Daily energy production from PV'
 xlabel 'Day of the year (day)'
 ylabel 'Energy (Wh)'

 % cluster the data accoring to the daily energy 
 %sort the data in asceding order accoring to their daily energy
 [B,I] = sort(DailyEnPV);
 
 figure (4);
 plot(B);
 title 'Daily energy PV out - annual duration curve '
 xlabel 'Day of the year (day)'
 ylabel 'Energy (Wh)'
 
% %  [idx,C] = kmeans(AnualPpv',3);

for i=1:noOfClusters
     plot(x_time,C(i,:));
     xlabel 'time (h)'
     ylabel 'PV out (W)' 
     strcat('cluster', num2str(i))
     title (strcat('cluster', num2str(i)))
     print(strcat('cluster', num2str(i)),'-dpng')
 end
   