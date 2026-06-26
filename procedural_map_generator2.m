% Authers: Alexander, Boas, Oscar
%Datum: 25-6-2026
% Met dit programma word van een random grid van 0 en 1 een kaart gemaakt.

clear all;
close all;
clc;

% Initializeer de begin settings
data.world = false(500, 500);
data.generation = 0;
data.edit_dlg = true;
data.birth_threshold = 13;
data.survival_threshold = 12;
data.density = 0.5;
data.max_generations = 50;
data.seed = 123456789;
data.sizeY = 500;
data.sizeX = 500;
screensize = get(0.0, 'screensize')(3:4);

% Maak het venster aan
data.fig = figure(
  'name', "Procedural world generation",
  'numbertitle', 'off',
  'menubar', 'none',
  'resize', 'off',
  'color', [0.03 0.28 0.25],
  'position', [(screensize(1)-1000)/2 (screensize(2)-800)/2 1000 800]
);

data.axs = axes(
  'units', 'pixels',
  'position', [1 101 700 700]
);

% Zet de kleuren voor tijdens de simulatie
% Dit hebben we met een colormap gemaakt van 120 groot zodat je dan kan
% instellen hoeveel dingen bijvoorbeeld diep water moeten zijn
% Anders zet octave zelf de schaal neer van 1-24 neighbors voor diep water
% dan 25-48 voor midden water etc
cmap = zeros(121, 3);
cmap(1:9,   :) = repmat([0.00 0.05 0.20], 9, 1);   % 0-8:   diep water
cmap(10:34,  :) = repmat([0.05 0.20 0.50], 25, 1);   %9-33:  midden water
cmap(35:54,  :) = repmat([0.30 0.55 0.80], 20, 1);   % 34-53:  licht water
cmap(55:88,  :) = repmat([0.85 0.80 0.45], 34, 1);   % 54-87:  zand
cmap(89:121, :) = repmat([0.15 0.55 0.20], 33, 1);   % 88-120: gras
colormap(data.axs, cmap);

% Reset knop
data.reset_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [21 20 210 60],
  'backgroundcolor', [0.8 0.6 0.5],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Reset',
  'fontsize', 24,
  'tooltipstring', 'Reset the world with random living cells',
  'callback', @click_reset
);

% Toggle step knop
data.step_btn = uicontrol(
  'style', 'togglebutton',
  'units', 'pixels',
  'position', [255 20 210 60],
  'backgroundcolor', [0.5 0.9 0.5],
  'string', 'Start',
  'fontsize', 24,
  'tooltipstring', 'Start the simulation!',
  'callback', @click_toggle_step
);

% Generatie label
data.generation_lbl = uicontrol(
  'style', 'text',
  'units', 'pixels',
  'position', [740 20 220 60],
  'backgroundcolor', [0.5 0.5 0.9],
  'foregroundcolor', [0.8 0.8 1.0],
  'string', 'Generation: 0',
  'fontsize', 20,
  'fontangle', 'italic'
);

% Save knop
data.save_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [740 650 220 40],
  'backgroundcolor', [0.8 0.3 0.2],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Save',
  'fontsize', 14,
  'tooltipstring', 'Save the world to a file',
  'callback', @click_save
);

% Biome maak knop
data.biomes_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [740 550 220 40],
  'backgroundcolor', [169/255 71/255 255/255],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Add biomes',
  'fontsize', 14,
  'tooltipstring', 'Save the world to a file',
  'callback', @click_add_biomes
);

% Load knop
data.load_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [740 600 220 40],
  'backgroundcolor', [0.7 0.3 0.7],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Load',
  'fontsize', 14,
  'tooltipstring', 'Load the world from a file',
  'callback', @click_load
);

% Setting knop
data.settings_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [490 20 210 60],
  'backgroundcolor', [0.5 0.7 0.9],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Settings',
  'fontsize', 24,
  'callback', @click_settings
);

% Maak nieuwe seed aan
data.rand_seed_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [740 700 220 40],
  'backgroundcolor', [0.9 0.5 0.7],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Randomize seed',
  'fontsize', 14,
  'callback', @click_random_seed
);

% Seed label
data.seed_lbl = uicontrol(
  'style', 'text',
  'units', 'pixels',
  'position', [740 750 220 40],
  'backgroundcolor', [0.3 0.6 0.3],
  'foregroundcolor', [0.8 1.0 0.8],
  'string', ['Seed: ' num2str(data.seed)],
  'fontsize', 14,
  'fontangle', 'italic'
);

% Hiermee maken we de img aan met de kleurschaal van 0,120 dit is voor de colormap van eerder
data.img = imagesc(data.axs, zeros(data.sizeY, data.sizeX), [0 120]);
axis(data.axs, 'off');

% Sla shared data op
guidata(data.fig, data);


% Callback functies
function click_reset(source, event)
  data = guidata(source);

  % Stop de toggle knop en zet naar start
  set(data.step_btn, 'Value', 0);
  set(data.step_btn, 'string', 'Start');
  % Set de RNG naar de seed
  rng(data.seed);
  % Maak de noise map aan met een density gegeven door de user anders 0.5
  data.world = (rand(data.sizeY, data.sizeX) < data.density);
  % Set generaties naar nul en hun labels
  data.generation = 0;
  set(data.generation_lbl, 'string', 'Generation: 0');
  set(data.seed_lbl, 'string', ['Seed: ' num2str(data.seed)]);

  % Bereken meten neighbors zodat give_colors werkt
  data.neighbors = conv2(double(data.world), ones(11,11), 'same') - double(data.world);

  % Save colors en zet de kleuren
  guidata(source, data);
  give_colors(source, event);
endfunction


function give_colors(source, event)
  % Deze functie zet de kleuren van de kaart
  data = guidata(source);
  % de colormap heeft hij al doordat we heb aan data.axs hebben gevoegt.
  set(data.img, 'cdata', data.neighbors);
  axis(data.axs, 'off');
  guidata(source, data);
endfunction

% Set de toggle knop
function click_toggle_step(source, event)
  data = guidata(source);

  % kleur van de toggle knop veranderen om activiteit te zien
  set(data.step_btn, 'backgroundcolor', [1.0 0.0 0.0]);
  set(data.step_btn, 'string', 'Stop');
  drawnow;

  while (get(source, 'Value') == 1) && data.generation < data.max_generations


    % Met conv2 bereken je de som van alle waarden in het venster van data.world om area
    % met same is de output kaart even groot als de input
    % Count living neighbours for simulation (5x5 area)
    neighbors = conv2(double(data.world), ones(5,5), 'same') - double(data.world);

    % Tell levende cellen om kleuren te geven, (area 11x11)
    neighbors_kleur = conv2(double(data.world), ones(11,11), 'same') - double(data.world);

    data.neighbors = neighbors_kleur;

    % Birth en survival regels toepassen
    birth    = (~data.world) & (neighbors >= data.birth_threshold);
    survival =   data.world  & (neighbors >= data.survival_threshold);
    data.world = birth | survival;

    % Update generation counter
    data.generation++;
    set(data.generation_lbl, 'string', ['Generation: ' int2str(data.generation)]);

    % Schrijf data op en set kleuren
    guidata(source, data);
    give_colors(source, event);

    pause(0.001);
  endwhile
  % Zet kleuren en knop om naar start
  give_colors(source, event);
  set(data.step_btn, 'backgroundcolor', [0.5 0.9 0.5]);
  set(data.step_btn, 'string', 'Start');
  set(data.step_btn, 'Value', 0);
endfunction

%random seed aanmaken
function click_random_seed(source, event)
  data = guidata(source);
  data.seed = randi(2147483647);
  set(data.seed_lbl, 'string', ['Seed: ' num2str(data.seed)]);
  guidata(source, data);
  click_reset(source, event);
  endfunction


function click_add_biomes(source, event)
  data = guidata(source);

  nblob = 8;   % grofheid van de ruis: 8x8 willekeurige punten die
               % we straks uitsmeren over het hele raster.
               % Kleiner = grovere vlekken, groter = fijnere ruis.

  % Maak sample-coordinaten die het kleine nblob x nblob grid
  % uitrekken tot de volledige rasterafmeting. XI/YI lopen van
  % 1..nblob, maar met sizeX resp. sizeY tussenstappen.
  [XI, YI] = meshgrid(linspace(1, nblob, data.sizeX), ...
                      linspace(1, nblob, data.sizeY));

  % randn(nblob) = 8x8 matrix met willekeurige getallen.
  % interp2(..., 'spline') interpoleert die vloeiend op tot de

  % Twee aparte trekkingen: 1 voor temperatuur, 1 voor vocht.
  smudge  = interp2(randn(nblob), XI, YI, 'spline');   % ruislaag 1 (temp)
  smudge2 = interp2(randn(nblob), XI, YI, 'spline');   % ruislaag 2 (vocht)

  % Basistemperatuur: -abs(rij - middenrij) is 0 in het midden en
  % wordt steeds negatiever richting de randen  (1:sizeY)' is een KOLOMvector, dus deze gradient hangt
  % alleen af van de rij (Y)
  T = -abs((1:data.sizeY)' - data.sizeY/2) + 60*smudge;

  % Vochtigheid is simpelweg de tweede ruislaag: puur willekeurig
  % verdeeld en losgekoppeld van de temperatuur.
  M = smudge2;

  %    Zo kun je met vaste drempels (0.33, 0.5, 0.66, ...) werken
  %    ongeacht de absolute waarden van T en M.
  %    De (:) maakt er even 1 lange kolom van, zodat min/max over
  %    de HELE matrix gaan en niet per kolom.

  Tn = (T - min(T(:))) / (max(T(:)) - min(T(:)));   % temp  0..1
  Mn = (M - min(M(:))) / (max(M(:)) - min(M(:)));   % vocht 0..1

  %    12 rijen, elke rij is 1 biome-kleur als [R G B] in 0..1.
  %    De rij-NUMMERS (1 t/m 12) gebruiken we straks als index.

  palette = [ ...
    0.00 0.05 0.20;   % 1  diep water
    0.05 0.20 0.50;   % 2  midden water
    0.30 0.55 0.80;   % 3  ondiep water
    0.85 0.80 0.45;   % 4  strand / zand
    0.95 0.96 0.98;   % 5  sneeuw
    0.65 0.70 0.62;   % 6  toendra    (koud + droog)
    0.13 0.35 0.22;   % 7  taiga      (koud + nat)
    0.30 0.62 0.28;   % 8  grasland   (gematigd + droog)
    0.12 0.45 0.18;   % 9  bos        (gematigd + nat)
    0.62 0.62 0.28;   % 10 savanne    (heet + droog)
    0.05 0.40 0.12;   % 11 regenwoud  (heet + nat)
    0.82 0.72 0.40];  % 12 woestijn   (zeer heet + droog)

  %    idx wordt een matrix even groot als het raster, met in elke
  %    cel een getal 1..12 dat verwijst naar een rij in 'palette'.

  idx = zeros(data.sizeY, data.sizeX);   % start: alles op 0

  % Weinig buren = laag = water; veel buren = hoog = land.
  % De grenzen 10/34/54/88 bepalen waar de waterlijnen liggen.
  n = data.neighbors;
  idx(n < 10)            = 1;   % heel laag  -> diep water
  idx(n >= 10 & n < 34)  = 2;   % laag       -> midden water
  idx(n >= 34 & n < 54)  = 3;   % iets hoger -> ondiep water
  idx(n >= 54 & n < 88)  = 4;   % kustlijn   -> strand / zand
  inland = n >= 88;             % alles vanaf 88 buren is land

  % Vocht in twee klassen: droog vs nat (grens op 0.5).
  dry = Mn < 0.5;   wet = ~dry;

  % 'inland &' zit er telkens bij, zodat water niet per
  % ongeluk meegekleurd wordt.
  cold = inland & Tn <  0.33;
  temp = inland & Tn >= 0.33 & Tn < 0.66;
  hot  = inland & Tn >= 0.66;

  % Combineer temp-band x vochtklasse -> 6 land-biomes.
  idx(cold & dry) = 6;    idx(cold & wet) = 7;
  idx(temp & dry) = 8;    idx(temp & wet) = 9;
  idx(hot  & dry) = 10;   idx(hot  & wet) = 11;

  idx(inland & Tn < 0.12)        = 5;    % sneeuw op de koudste cellen
  idx(inland & Tn > 0.88 & dry)  = 12;   % woestijn op de heetste droge cellen

  %    We zoeken per cel de kleur op in 'palette' en bouwen een
  %    HxWx3 afbeelding (aparte R-, G- en B-laag).

  idxv = idx(:);   % maak er 1 lange kolomvector van (HxW elementen)

  % palette(idxv, 1) pakt voor elke cel de R-waarde uit de tabel;
  % reshape stopt dat resultaat terug in de rastervorm.
  R = reshape(palette(idxv, 1), data.sizeY, data.sizeX);
  G = reshape(palette(idxv, 2), data.sizeY, data.sizeX);
  B = reshape(palette(idxv, 3), data.sizeY, data.sizeX);

  % cat(3, ...) stapelt de drie lagen tot 1 kleurafbeelding (HxWx3).
  rgb = cat(3, R, G, B);

  % Zet de nieuwe pixels in het bestaande image-object en verberg
  % de assen voor een schone weergave.
  set(data.img, 'cdata', rgb);
  axis(data.axs, 'off');

  % Sla de (eventueel gewijzigde) state weer op, zodat andere
  % callbacks dezelfde data te zien krijgen.
  guidata(source, data);
endfunction

% Hiermee kan de gebruiker de settings invulen die ze willen
function click_settings(source, event)
  data = guidata(source);

  % Input vraag
  answer = inputdlg(
    {'Seed (rng):', 'Aantal random land/water (0.45 - 0.55 hoger = meer land):', 'Wereld grootte (pixels):', 'Max generaties:', 'Geboorte drempel:', 'Overlevings drempel:'},
    'Settings',
    1,
    {num2str(data.seed), num2str(data.density), num2str(data.sizeX), num2str(data.max_generations), num2str(data.birth_threshold), num2str(data.survival_threshold)}
  );

  if ~isempty(answer)
    data.seed               = str2num(answer{1});
    if data.seed > 2147483647
      data.seed = 2147483647;
    endif
    if data.seed < 0
      data.seed = 0;
    endif
    data.density            = str2num(answer{2});
    data.sizeX              = str2num(answer{3});
    data.sizeY              = str2num(answer{3});
    data.max_generations    = str2num(answer{4});
    data.birth_threshold    = str2num(answer{5});
    data.survival_threshold = str2num(answer{6});
    set(data.seed_lbl, 'string', ['Seed: ' num2str(data.seed)]);
    guidata(source, data);
    click_reset(source, event);
  endif
endfunction

% Save knop
function click_save(source, event)
  data = guidata(source);
  [filename, filepath] = uiputfile(
    {"*.csv;*.txt", "Text file"; "*.gif;*.bmp;*.png", "Image file"},
    'Specify the filename to save'
  );
  if length(filename) > 4 & ischar(filename)
    if endsWith(filename, '.csv') || endsWith(filename, '.txt')
      csvwrite(strcat(filepath, filename), data.world);
    elseif endsWith(filename, '.gif') || endsWith(filename, '.bmp') || endsWith(filename, '.png')
      colormap = get(data.axs, 'colormap');
      imwrite(uint8(data.world), colormap, strcat(filepath, filename));
    endif
  endif
endfunction

% Load knop
function click_load(source, event)
  [filename, filepath] = uigetfile(
    {"*.csv;*.txt", "Text file"; "*.gif;*.bmp;*.png", "Image file"},
    'Specify the filename to load'
  );
  if length(filename) > 4 & ischar(filename)
    data = guidata(source);
    if endsWith(filename, '.csv') || endsWith(filename, '.txt')
      data.world = csvread(strcat(filepath, filename));
    elseif endsWith(filename, '.gif') || endsWith(filename, '.bmp') || endsWith(filename, '.png')
      data.world = logical(imread(strcat(filepath, filename)));
    endif
    data.neighbors = conv2(double(data.world), ones(11,11), 'same') - double(data.world);
    data.generation = 0;
    set(data.generation_lbl, 'string', 'Generation: 0');
    guidata(source, data);
    give_colors(source, event);
  endif
endfunction

% Knop voor de wiki
data.wiki_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [740 500 220 40],
  'backgroundcolor', [176/255, 11/255, 30/255],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Our wiki',
  'fontsize', 14,
  'tooltipstring', 'Load the world from a file',
  'callback', @click_wiki
);

% Redirect voor de wiki
function click_wiki(source, event)
  data = guidata(source);
  web("http://langers.nl/wiki/doku.php?id=procedural_world_generation_2026:welkom");
endfunction

% Automatisch reseten van veld wanneer het programma word opgestart
click_reset(data.fig, []);
