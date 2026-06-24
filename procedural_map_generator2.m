% Initialize variables

clear all;
close all;

sizeY = 500;
sizeX = 500;
data.world = false(sizeY, sizeX);
data.generation = 0;
data.edit_dlg = true;


% Create window with various UI elements

data.fig = figure(
  'name', "Falling sand game",
  'numbertitle', 'off',
  'menubar', 'none',
  'resize', 'off',
  'color', [0.03 0.28 0.25],
  'position', [260 80 1000 600]
);

data.axs = axes(
  'units', 'pixels',
  'position', [1 101 500 500]
);

cmap = zeros(121, 3);
cmap(1:14,   :) = repmat([0.00 0.05 0.20], 14, 1);   % 0-13:   diep water
cmap(15:34,  :) = repmat([0.05 0.20 0.50], 20, 1);   % 14-33:  midden water
cmap(35:54,  :) = repmat([0.30 0.55 0.80], 20, 1);   % 34-53:  licht water
cmap(55:88,  :) = repmat([0.85 0.80 0.45], 34, 1);   % 54-87:  zand
cmap(89:121, :) = repmat([0.15 0.55 0.20], 33, 1);   % 88-120: gras
colormap(data.axs, cmap);

data.reset_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [21 21 200 60],
  'backgroundcolor', [0.8 0.6 0.5],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', '♻   reset',
  'fontsize', 24,
  'tooltipstring', 'Reset the world with random living cells',
  'callback', @click_reset
);

data.step_btn = uicontrol(
  'style', 'togglebutton',
  'units', 'pixels',
  'position', [240 20 200 60],
  'backgroundcolor', [0.5 0.9 0.5],
  'string', 'Start',
  'fontsize', 24,
  'tooltipstring', 'Start the simulation!',
  'callback', @click_toggle_step
);

data.generation_lbl = uicontrol(
  'style', 'text',
  'units', 'pixels',
  'position', [691 31 220 40],
  'backgroundcolor', [0.5 0.5 0.9],
  'foregroundcolor', [0.8 0.8 1.0],
  'string', 'Generation: 0',
  'fontsize', 20,
  'fontangle', 'italic'
);

data.save_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [1161 21 200 60],
  'backgroundcolor', [0.8 0.8 0.6],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', '📥   save',
  'fontsize', 24,
  'tooltipstring', 'Save the world to a file',
  'callback', @click_save
);

data.load_btn = uicontrol(
  'style', 'pushbutton',
  'units', 'pixels',
  'position', [1381 21 200 60],
  'backgroundcolor', [0.8 0.8 0.6],
  'foregroundcolor', [1.0 1.0 1.0],
  'string', '📤   load',
  'fontsize', 24,
  'tooltipstring', 'Load the world from a file',
  'callback', @click_load
);

data.img = imagesc(data.axs, zeros(sizeY, sizeX), [0 120]);
axis(data.axs, 'off');

% Store shared data
guidata(data.fig, data);


% Define callback functions

function click_reset(source, event)
  data = guidata(source);

  set(data.step_btn, 'Value', 0);

  % Update world
  data.world = (rand(size(data.world)) < 0.47);
  data.generation = 0;

  % Clear stale neighbors
  if isfield(data, 'neighbors')
    data = rmfield(data, 'neighbors');
  endif

  set(data.generation_lbl, 'string', 'Generation: 0');
  set(data.img, 'cdata', zeros(size(data.world)));

  % Store shared data
  guidata(source, data);
endfunction

function give_colors(source, event)
  data = guidata(source);

  if ~isfield(data, 'neighbors')
    return;
  endif

  set(data.img, 'cdata', data.neighbors);
  axis(data.axs, 'off');

  guidata(source, data);
endfunction

% Run the simulation while the toggle button is pressed
function click_toggle_step(source, event)
  data = guidata(source);

  % Set togglebutton to purple while running
  set(data.step_btn, 'backgroundcolor', [0.7 0.3 0.7]);

  while (get(source, 'Value') == 1) && data.generation < 50

    data = guidata(source);

    % Count living neighbours for simulation (5x5 area)
    neighbors = zeros(size(data.world));
    for stepx = -2:+2
      for stepy = -2:+2
        neighbors += circshift(data.world, [stepx stepy]);
      endfor
    endfor
    neighbors -= data.world;

    % Count living neighbours for color (11x11 area)
    neighbors_kleur = zeros(size(data.world));
    for stepx = -5:+5
      for stepy = -5:+5
        neighbors_kleur += circshift(data.world, [stepx stepy]);
      endfor
    endfor
    neighbors_kleur -= data.world;

    data.neighbors = neighbors_kleur;

    % Birth/survival rules
    birth    = (~data.world) & (neighbors >= 13);
    survival =   data.world  & (neighbors >= 12);
    data.world = birth | survival;

    % Update generation counter
    data.generation++;
    set(data.generation_lbl, 'string', ['Generation: ' int2str(data.generation)]);

    % Store shared data then apply colors
    guidata(source, data);
    give_colors(source, event);

    pause(0.01);
  endwhile

  give_colors(source, event);

  % Set the button colour back to the original
  set(data.step_btn, 'backgroundcolor', [0.5 0.9 0.5]);
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
    set(data.img, 'cdata', zeros(size(data.world)));
    data.generation = 0;
    set(data.generation_lbl, 'string', 'Generation: 0');
    guidata(source, data);
  endif
endfunction
