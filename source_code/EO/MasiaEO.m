
function [imgOut, bWarning] = MasiaEO(img, maxOutLuminance, Masia_noise_removal, Masia_multi_reg, gammaRemoval)
%
%       [imgOut, bWarning] = MasiaEO(img, maxOutLuminance, Masia_noise_removal, Masia_multi_reg, gammaRemoval)
%
%
%        Input:
%           -img: input LDR image with values in [0,1]
%           -maxOutLuminance: maximum luminance output in cd/m^2
%           -Masia_noise_removal: if set to 1 it removes noise or artifacts
%           using the bilateral filter
%           -Masia_multi_reg: if set to 1 it applies multi regression (2),
%           otherwise it uses SIGGRAPH ASIA paper regression (1)
%           -gammaRemoval: the gamma value to be removed if known
%
%        Output:
%           -imgOut: an expanded image
%           -bWarning: a flag if there was gamma inversion
%
%     Copyright (C) 2011-16  Francesco Banterle
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
%     The papers describing this technique are:
%     1) "Evaluation of Reverse Tone Mapping Through Varying Exposure Conditions"
%     By B. Masia, S. Augustin, R. Fleming, O. Sorkine, D. Gutierrez
%     in SIGGRAPH ASIA 2009   
%
%     2) "Dynamic Range Expansion Based on Image Statistics"
%     By B. Masia, A. Serrano, D. Gutierrez
%     in Multimedia Tools and Applications 2015     
%

check13Color(img);

if(~exist('maxOutLuminance', 'var'))
    maxOutLuminance = 3000.0;
end

if(maxOutLuminance < 0.0)
    maxOutLuminance = 3000.0;
end

if(~exist('gammaRemoval', 'var'))
    gammaRemoval = -1;
end

if(gammaRemoval > 0.0)
    img=img.^gammaRemoval;
end

%
%
%

if(~exist('Masia_noise_removal', 'var'))
    Masia_noise_removal = 1;
end

if(~exist('Masia_multi_reg', 'var'))
    Masia_multi_reg = 0;
end

bWarning = 0;

%Calculate luminance
L = lum(img);

%Calculate image statistics
Lav  = logMean(L);
maxL = MaxQuart(L, 0.99);
minL = MaxQuart(L(L > 0), 0.01);
imageKey = (log(Lav) - log(minL)) / (log(maxL) - log(minL));

%Calculate the gamma correction value
if(Masia_multi_reg == 0)
    a_var = 10.44;
    b_var = -6.282;
    gamma_cor = imageKey * a_var + b_var;
else
    %percentage of over-exposed pixels
    [r,c] = size(L);
    p_ov = length(find((L * 255) >= 254 )) / (r * c) * 100.0;
    %Equation 5 of (2) paper
    gamma_cor = 2.4379 + 0.2319 * log(Lav) - 1.1228 * imageKey + 0.0085 * p_ov;
end

if(gamma_cor <= 0.0)
    disp('WARNING: gamma_cor value is negative so the image may have a false color appearance.');
    bWarning = 1;
end

%Bilateral filter to avoid to boost noise/artifacts
if(Masia_noise_removal)
    %note that the original paper does not provide parameters for filtering
    Lbase = bilateralFilter(L);
    Ldetail = RemoveSpecials(L ./ Lbase);
    Lexp = Ldetail .* (Lbase.^gamma_cor);
else
    Lexp = L.^gamma_cor;
end

%Changing luminance
imgOut = ChangeLuminance(img, L, Lexp * maxOutLuminance);

end
