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
  'position', [1 101 500 500],
  'colormap', [0.2 0.2 0.2; 0.8 0.8 0.8]
);
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
data.img = imagesc(data.axs, data.world, [0.0 1.0]);
axis(data.axs, 'off');

% Store shared data
guidata(data.fig, data);


% Define callback functions

function click_reset(source, event)
  % Ask for confirmation
    % Get shared data
    data = guidata(source);

    set(data.step_btn, 'Value', 0);

    % Update world
    data.world = (rand(size(data.world)) < 0.5);
    set(data.img, 'cdata', data.world);
    % Update generation counter
    data.generation = 0;
    set(data.generation_lbl, 'string', 'Generation: 0');
    % Store shared data
    guidata(source, data);
endfunction


function click_step(source, event)
  % Get shared data
  data = guidata(source);
  % Count living neighbours explicitly (all 8 directions, no self)
  w = double(data.world);
  neighbors = circshift(w, [-1 -1]) + circshift(w, [-1  0]) + circshift(w, [-1 +1]) + ...
              circshift(w, [ 0 -1]) +                          circshift(w, [ 0 +1]) + ...
              circshift(w, [+1 -1]) + circshift(w, [+1  0]) + circshift(w, [+1 +1]);
  % B5678/S45678 (Vote rule)
  % Birth: dead cell with 5, 6, 7 or 8 neighbours becomes alive
  birth    = (~data.world) & (neighbors >= 5);
  % Survival: living cell with 4, 5, 6, 7 or 8 neighbours stays alive
  survival =   data.world  & (neighbors >= 4);
  data.world = birth | survival;
  set(data.img, 'cdata', data.world);
  % Update generation counter
  data.generation++;
  set(data.generation_lbl, 'string', ['Generation: ' int2str(data.generation)]);
  % Store shared data
  guidata(source, data);
endfunction



% Run the simulation while the toggle button is pressed
function click_toggle_step(source, event)
  data = guidata(source);

  % Set togglebutton to purple while running
  set(data.step_btn, 'backgroundcolor', [0.7 0.3 0.7]);

  % Advance the simulation by 1 step/generation, up to 50 generations
  while (get(source, 'Value') == 1) && data.generation < 50

    % Get shared data
    data = guidata(source);

    % Count living neighbours (5x5 area, cell itself not counted)
    neighbors = zeros(size(data.world));
    for stepx = -2:+2
      for stepy = -2:+2
        neighbors += circshift(data.world, [stepx stepy]);
      endfor
    endfor
    neighbors -= data.world;

    % B5678/S45678 (Vote rule) on the 5x5 neighbourhood
    % Birth: dead cell with enough living neighbours becomes alive
    birth    = (~data.world) & (neighbors >= 13);
    % Survival: living cell with enough living neighbours stays alive
    survival =   data.world  & (neighbors >= 12);
    data.world = birth | survival;
    set(data.img, 'cdata', data.world);

    % Update generation counter
    data.generation++;
    set(data.generation_lbl, 'string', ['Generation: ' int2str(data.generation)]);

    % Store shared data
    guidata(source, data);
    pause(0.001);
  endwhile

  % Set the button colour back to the original
  set(data.step_btn, 'backgroundcolor', [0.5 0.9 0.5]);

  % --- When the simulation has finished, show the heat spreading out ---
  if data.generation >= 50

    % Starting heat field: density of living cells.
    % Count living neighbours in a 21x21 area around each cell.
    heat = zeros(size(data.world));
    for stepx = -10:+10
      for stepy = -10:+10
        heat += circshift(data.world, [stepx stepy]);
      endfor
    endfor
    heat -= data.world;

    % Scale the field to a 0..31 temperature range (guard against an empty world)
    heat_max = 31;
    m = max(heat(:));
    if m > 0
      heat = heat_max * heat / m;
    endif

    % Open a separate window for the heat view
    nb_fig = figure('name', 'Heat spreading', 'numbertitle', 'off');
    img = imagesc(heat, [0 heat_max]);
    axis image;
    axis off;
    colormap(nb_fig, 'hot');   % black -> red -> yellow -> white
    colorbar;
    title('Heat: step 0');

    % Diffusion settings
    iterations    = 200;   % more steps = more spreading
    alpha         = 0.24;   % diffusion strength, must stay <= 0.25 to be stable
    refresh_every = 6;      % redraw every N steps (lower = smoother, slower)

    % Let the heat spread / average out
    for step = 1:iterations
      % Sum of the 4 direct neighbours (edges wrap around via circshift)
      neighbours = circshift(heat, [ 1  0]) + circshift(heat, [-1  0]) + ...
                   circshift(heat, [ 0  1]) + circshift(heat, [ 0 -1]);

      % Heat equation: nudge every cell towards its neighbours' average
      heat = heat + alpha * (neighbours - 4 * heat);

      if mod(step, refresh_every) == 0
        set(img, 'cdata', heat);
        title(['Heat: step ' int2str(step)]);
        drawnow;
      endif
    endfor

    title(['Heat: step ' int2str(iterations) ' (done)']);
  endif
endfunction




function click_save(source, event)
  % Get shared data
  data = guidata(source);
  % Ask user for file name
  [filename, filepath] = uiputfile(
    {"*.csv;*.txt", "Text file"; "*.gif;*.bmp;*.png", "Image file"},
    'Specify the filename to save'
  );
  % Save as text or image file, if provided
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
  % Ask user for file name
  [filename, filepath] = uigetfile(
    {"*.csv;*.txt", "Text file"; "*.gif;*.bmp;*.png", "Image file"},
    'Specify the filename to load'
  );
  % Load from text or image file, if provided
  if length(filename) > 4 & ischar(filename)
    data = guidata(source);
    if endsWith(filename, '.csv') || endsWith(filename, '.txt')
      data.world = csvread(strcat(filepath, filename));
    elseif endsWith(filename, '.gif') || endsWith(filename, '.bmp') || endsWith(filename, '.png')
      data.world = logical(imread(strcat(filepath, filename)));
    endif
    % Update app window
    set(data.img, 'cdata', data.world);
    data.generation = 0;
    set(data.generation_lbl, 'string', 'Generation: 0');
    % Store shared data
    guidata(source, data);
  endif
endfunction
