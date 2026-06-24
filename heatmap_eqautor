sizeX = 500;
sizeY = 500;
rng('shuffle');                                    % new pattern every run

nblob = 8;                                         % fewer = bigger smudges
[XI, YI] = meshgrid(linspace(1,nblob,sizeX), linspace(1,nblob,sizeY));
smudge = interp2(randn(nblob), XI, YI, 'spline');

T = -abs((1:sizeY)' - sizeY/2) + 60*smudge;        % hot middle, cold top/bottom

imagesc(T); colormap(jet);                         % add ; colorbar  if you want a scale
