function imgOut = KuoEO(img, LMax, gammaRemoval)
%
%       imgOut = KuoEO(img, LMax, gammaRemoval)
%
%        Input:
%           -img:  input LDR image with values in [0,1]
%           -LMax: maximum luminance output in cd/m^2
%           -gammaRemoval: the gamma value to be removed if known
%
%        Output:
%           -imgOut: an expanded image
%
%     Copyright (C) 2013-14  Francesco Banterle
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%     The paper describing this technique is:
%     "CONTENT-ADAPTIVE INVERSE TONE MAPPING"
%     by Pin-Hung Kuo, Chi-Sun Tang, and Shao-Yi Chien
%     in VCIP 2012, San Diego, CA, USA
%

%is it a three color channels image?
check13Color(img);

disp('Note the SVM classifier is missing, please select LMax carefully.');
disp('This has to be chosen based on the content; indoor, outdoor, daylight, etc.');

if(~exist('gammaRemoval','var'))
    gammaRemoval = -1.0;
end

if(gammaRemoval > 0.0)
    img = img.^gammaRemoval;
end

%Calculate luminance
Ld = lum(img);

%Inverse Schlick Operator
p = 30; %as in the original paper
Lexp = (Ld * LMax) ./ (p * (1 - Ld) + Ld);

%Computing the expand map
expand_map = KuoExpandMap(Ld);

Lexp = Lexp .* expand_map + (1.0 - expand_map) .* Ld;
hdrimwrite(expand_map,'emap.pfm');

%Changing luminance
imgOut = ChangeLuminance(img, Ld, Lexp);

end