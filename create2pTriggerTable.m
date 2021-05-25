% clear 
% close all

%% INPUT PARAMETERS: UPDATE
dataPath = 'E:\Data\20200910\';
P = struct;
% P.fps = 4.69; % VOLUME RATE (Hz)
P.fps = hSI.hRoiManager.scanFrameRate;
P.duration_trial_secs = 60*9; % FULL EXPERIMENT TIME (S)
P.duration_baseline_secs = 60; % AMOUNT OF DEAD TIME BEFORE STIM. (S)

%%
P.period_arduino_clk_secs = round(P.fps*5)/P.fps;
P.arduino_clk_interval = round(P.fps*5); 

P.offset_visual_secs = 0;%round(P.fps*5)/P.fps;
P.n_visual = 1;
P.period_visual_secs = round(P.fps*5)/P.fps; 
P.visual_interval = round(P.fps*5);
P.duration_visual_secs = 1;  % only controls pulse duration and not stimulus duration\

P.n_whisker = 2;
P.period_whisker_secs = round(P.fps*5)/P.fps;%(P.n_visual + 1) * P.period_visual_secs;
P.whisker_interval = round(P.fps*5);
P.duration_whisker_secs = 0.5;

P.daq_dev = 'PXI1slot4';

%P.daq_dev = 'Dev4';
P.line_arduino_clk = 0;
P.line_ir_led = nan;
P.line_whisker = 1;
P.line_wisim_led = 2;
P.line_visual = 3; % --> jump wire to port0:4 for other matlab

%%

%%
do_table = zeros(ceil(P.fps * P.duration_trial_secs), 4);

do_table(1 : P.arduino_clk_interval : end, P.line_arduino_clk + 1) = 1;

%do_table(1 : P.period_ir_led_secs      * P.wisim_fps : end, 2) = 1;

whisker_dframes = ceil(P.duration_whisker_secs * P.fps);

stim_start = round(P.duration_baseline_secs*P.fps);
stim_end = round(P.duration_trial_secs*P.fps);

whisker_offsets = stim_start : P.whisker_interval : stim_end;
for i = 1:numel(whisker_offsets)
    if mod(i-P.n_whisker,3) == 0  % leave out every P.n_visual'th pulse to make space for whisker stim
        continue;
    else
        do_table(whisker_offsets(i) : whisker_offsets(i) + whisker_dframes, P.line_whisker + 1) = 1;
    end
end

visual_dframes = ceil(P.duration_visual_secs * P.fps);
% visual_offsets = ((P.duration_baseline_secs + P.offset_visual_secs) : P.period_visual_secs : (P.duration_trial_secs - P.duration_visual_secs)) * P.fps;
visual_offsets = stim_start : P.visual_interval : stim_end;

for i = 1:numel(visual_offsets)
    if mod(i-P.n_visual,3) == 0  % leave out every P.n_visual'th pulse to make space for whisker stim
        continue;
    else
        do_table(visual_offsets(i) : (visual_offsets(i) + visual_dframes), P.line_visual + 1) = 1;
    end
end
%do_table(((P.duration_baseline_secs + P.offset_visual_secs) * P.wisim_fps) : (P.period_visual_secs  * P.wisim_fps) : end, P.line_visual + 1) = 1;

do_table(:, P.line_wisim_led + 1) = 1;
do_table(end + 1,:) = 0;  % set everything to zero after end of experiment

%%
figure;
hold on;
for i = 1:size(do_table,2)
    stairs(do_table(:,i) + (i-1) * 1.1);
end
hold off;

%%
do_sess = daq.createSession('ni');
do_ch = addDigitalChannel(do_sess, P.daq_dev, 'Port0/Line0:3', 'OutputOnly');
do_sess.IsContinuous = 0;
addClockConnection(do_sess, 'External', [P.daq_dev '/PFI6'], 'ScanClock');

%%
queueOutputData(do_sess, do_table);
save([dataPath 'pulse_config_' datestr(clock,'YYYY-mm-dd_HHMMSS') '.mat'], 'P', 'do_table');
disp(['Experiment start: ' datestr(clock,'YYYY-mm-dd_HHMMSS')]);
do_sess.startBackground();
