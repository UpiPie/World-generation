% Initialize variables

clear all;
close all;
clc;

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


% Create window with various UI elements

data.fig = figure(
  'name', "Procedural world generation",
  'numbertitle', 'off',
  'menubar', 'none',
  'resize', 'off',
  'color', [0.03 0.28 0.25],
  'position', [260 80 800 600]
);

data.axs = axes(
  'units', 'pixels',
  'position', [1 101 500 500]
);

cmap = zeros(121, 3);
cmap(1:9,   :) = repmat([0.00 0.05 0.20], 9, 1);   % 0-4:   diep water
cmap(10:34,  :) = repmat([0.05 0.20 0.50], 25, 1);   % 5-33:  midden water
cmap(35:54,  :) = repmat([0.30 0.55 0.80], 20, 1);   % 34-53:  licht water
cmap(55:88,  :) = repmat([0.85 0.80 0.45], 34, 1);   % 54-87:  zand
cmap(89:121, :) = repmat([0.15 0.55 0.20], 33, 1);   % 88-120: gras
colormap(data.axs, cmap);

data.reset_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [21 21 147 60],
  'backgroundcolor', [0.8 0.6 0.5],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Reset',
  'fontsize', 24,
  'tooltipstring', 'Reset the world with random living cells',
  'callback', @click_reset
);

data.step_btn = uicontrol(
  'style', 'togglebutton',
  'units', 'pixels',
  'position', [188 20 146 60],
  'backgroundcolor', [0.5 0.9 0.5],
  'string', 'Start',
  'fontsize', 24,
  'tooltipstring', 'Start the simulation!',
  'callback', @click_toggle_step
);

data.generation_lbl = uicontrol(
  'style', 'text',
  'units', 'pixels',
  'position', [540 20 220 60],
  'backgroundcolor', [0.5 0.5 0.9],
  'foregroundcolor', [0.8 0.8 1.0],
  'string', 'Generation: 0',
  'fontsize', 20,
  'fontangle', 'italic'
);

data.save_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [540 450 220 40],
  'backgroundcolor', [225/255, 176/255, 11/255],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Save',
  'fontsize', 14,
  'tooltipstring', 'Save the world to a file',
  'callback', @click_save
);

data.load_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [540 400 220 40],
  'backgroundcolor', [0.7 0.3 0.7],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Load',
  'fontsize', 14,
  'tooltipstring', 'Load the world from a file',
  'callback', @click_load
);

data.settings_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [354 20 147 60],
  'backgroundcolor', [0.5 0.7 0.9],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Settings',
  'fontsize', 24,
  'callback', @click_settings
);

data.rand_seed_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [540 500 220 40],
  'backgroundcolor', [0.9 0.5 0.7],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Randomize seed',
  'fontsize', 14,
  'callback', @click_random_seed
);

data.seed_lbl = uicontrol(
  'style', 'text',
  'units', 'pixels',
  'position', [540 550 220 40],
  'backgroundcolor', [0.3 0.6 0.3],
  'foregroundcolor', [0.8 1.0 0.8],
  'string', ['Seed: ' num2str(data.seed)],
  'fontsize', 14,
  'fontangle', 'italic'
);


data.img = imagesc(data.axs, zeros(data.sizeY, data.sizeX), [0 120]);
axis(data.axs, 'off');

% Store shared data
guidata(data.fig, data);


% Define callback functions

function click_reset(source, event)
  data = guidata(source);

  set(data.step_btn, 'Value', 0);

  rng(data.seed);
  data.world = (rand(data.sizeY, data.sizeX) < data.density);
  data.generation = 0;
  set(data.generation_lbl, 'string', 'Generation: 0');
  set(data.seed_lbl, 'string', ['Seed: ' num2str(data.seed)]);

  % Bereken meteen neighbors zodat give_colors werkt
  data.neighbors = conv2(double(data.world), ones(11,11), 'same') - double(data.world);

  guidata(source, data);
  give_colors(source, event);
endfunction


function give_colors(source, event)
  data = guidata(source);
  set(data.img, 'cdata', data.neighbors);
  axis(data.axs, 'off');

  guidata(source, data);
endfunction


function click_toggle_step(source, event)
  data = guidata(source);

  set(data.step_btn, 'backgroundcolor', [0.7 0.3 0.7]);

  while (get(source, 'Value') == 1) && data.generation < data.max_generations

    data = guidata(source);

    % Met conv2 bereken je de som van alle waarden in het venster van data.world om area
    % met same is de output kaart even groot als de input
    % Count living neighbours for simulation (5x5 area)
    neighbors = conv2(double(data.world), ones(5,5), 'same') - double(data.world);

    % Count living neighbours for color (11x11 area)
    neighbors_kleur = conv2(double(data.world), ones(11,11), 'same') - double(data.world);

    data.neighbors = neighbors_kleur;

    % Birth/survival rules
    birth    = (~data.world) & (neighbors >= data.birth_threshold);
    survival =   data.world  & (neighbors >= data.survival_threshold);
    data.world = birth | survival;

    % Update generation counter
    data.generation++;
    set(data.generation_lbl, 'string', ['Generation: ' int2str(data.generation)]);

    % Store shared data then apply colors
    guidata(source, data);
    give_colors(source, event);

    pause(0.001);
  endwhile

  give_colors(source, event);

  set(data.step_btn, 'backgroundcolor', [0.5 0.9 0.5]);
endfunction

function click_random_seed(source, event)
  data = guidata(source);
  data.seed = randi(2147483647);
  set(data.seed_lbl, 'string', ['Seed: ' num2str(data.seed)]);
  guidata(source, data);
  click_reset(source, event);
endfunction


function click_settings(source, event)
  data = guidata(source);

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



data.wiki_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [540 350 220 40],
  'backgroundcolor', [176/255, 11/255, 30/255],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', 'Our wiki',
  'fontsize', 14,
  'tooltipstring', 'Load the world from a file',
  'callback', @click_wiki
);

function click_wiki(source, event)
  data = guidata(source);
  web("http://langers.nl/wiki/doku.php?id=procedural_world_generation_2026:welkom");
endfunction

% Automatisch reset bij opstarten
click_reset(data.fig, []);
