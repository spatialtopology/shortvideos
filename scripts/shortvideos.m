function shortvideos(sub_num, biopac, debug)
% *************************************************************************
%   Program Name: self_other_task.m
%   Original Programmer: Luke Slipski
%   Created: December, 2, 2020
%   Project: Spacetop
%   This program executes the self-other task included in the Spatial
%   Topology Grant. It displays 5-10 second video clips from longer videos
%   that participants have already viewed during the functional alignment
%   video portion of the experiment. It then asks the participant to make
%   one of three types of judgements:
%   1.) Inclusion of Self in Other -- How much doesls the target character in
%    the video overlap with the participants sense of self?
%   2.) Likeability -- How much does the participant like the target
%   character in the video?
%   3.) Mentalizing -- A question unique to the video clip asking about
%   what the character in the video was thinking
%
%  Input:
%   1.) subjID -- A BIDS formatted subject identifier of the form
%   'spacetop_sub-001_tas-selfother_ses-03'
% *************************************************************************




%% -----------------------------------------------------------------------------
%                                Parameters
% ------------------------------------------------------------------------------
%% 0. Biopac parameters ________________________________________________________
% biopac channel
channel = struct;

channel.trigger     = 0;
channel.cue         = 1;
channel.movie       = 2;
channel.rating      = 3;

if biopac == 1
    script_dir = pwd;
    cd('/home/spacetop/repos/labjackpython');
    pe = pyenv;
    try
        py.importlib.import_module('u3');
    catch
        warning("u3 already imported!");
    end

    % py.importlib.import_module('u3');
    % Check to see if u3 was imported correctly
    % py.help('u3')
    channel.d = py.u3.U3();
    % set every channel to 0
    channel.d.configIO(pyargs('FIOAnalog', int64(0), 'EIOAnalog', int64(0)));
    for FIONUM = 0:7
        channel.d.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
    end
    cd(script_dir);
end



%% A. Psychtoolsbox parameters _________________________________________________
global p
Screen('Preference', 'SkipSyncTests', 0);
PsychDefaultSetup(2);

if debug
    ListenChar(0);
    PsychDebugWindowConfiguration;
end
screens                         = Screen('Screens'); % Get the screen numbers
p.ptb.screenNumber              = max(screens); % Draw to the external screen if avaliable
p.ptb.white                     = WhiteIndex(p.ptb.screenNumber); % Define black and white
p.ptb.black                     = BlackIndex(p.ptb.screenNumber);
[p.ptb.window, p.ptb.rect]      = PsychImaging('OpenWindow', p.ptb.screenNumber, p.ptb.black);
[p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize', p.ptb.window);
p.ptb.ifi                       = Screen('GetFlipInterval', p.ptb.window);
Screen('BlendFunction', p.ptb.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines
Screen('TextFont', p.ptb.window, 'Arial');
Screen('TextSize', p.ptb.window, 36);
[p.ptb.xCenter, p.ptb.yCenter]  = RectCenter(p.ptb.rect);
p.fix.sizePix                   = 40; % size of the arms of our fixation cross
p.fix.lineWidthPix              = 4; % Set the line width for our fixation cross
p.fix.xCoords                   = [-p.fix.sizePix p.fix.sizePix 0 0];
p.fix.yCoords                   = [0 0 -p.fix.sizePix p.fix.sizePix];
p.fix.allCoords                 = [p.fix.xCoords; p.fix.yCoords];
% empty options for video Screen
shader = [];
pixelFormat = [];
maxThreads = [];

iteration = 0;
escape = 0;

% Use blocking wait for new frames by default:
blocking = 1;

% Default preload setting:
preloadsecs = [];
% Playbackrate defaults to 1:
rate=1;



%% B. Directories ______________________________________________________________
ses_num = 3;
script_dir                      = pwd; % /home/spacetop/repos/shortvideos/scripts
main_dir                        = fileparts(script_dir); % /home/spacetop/repos/shortvideos
repo_dir                        = fileparts(fileparts(script_dir)); %/home/spacetop
taskname                        = 'shortvideos';

bids_string                     = [strcat('sub-', sprintf('%04d', sub_num)), ...
    strcat('_ses-',sprintf('%02d', ses_num)),...
    strcat('_task-', taskname),...
    ];
sub_save_dir = fullfile(main_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)),...
    strcat('ses-',sprintf('%02d', ses_num)),...
    'beh'  );
repo_save_dir = fullfile(repo_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)),...
    strcat('task-', taskname));
if ~exist(sub_save_dir, 'dir');    mkdir(sub_save_dir);     end
if ~exist(repo_save_dir, 'dir');    mkdir(repo_save_dir);   end


design_filename                 = fullfile(main_dir, 'design', strcat('task-shortvideos_counterbalance_ver-', sprintf('%03d', sub_num),'.csv'));
design_file                     = readtable(design_filename);

vid_filename                   = fullfile(main_dir, 'design', strcat('task-shortvideos_videometadata.csv'));
video_metadata                     = readtable(vid_filename);

trials_per_blk = 3;
%% C. Circular rating scale _____________________________________________________
image_filepath                  = fullfile(main_dir, 'stimuli', 'ratingscale');



ment_angry_scale                = fullfile(image_filepath, 'ratingscale-01ment_content-angry.png');
ment_calm_scale                 = fullfile(image_filepath, 'ratingscale-01ment_content-calm.png');
ment_danger_scale               = fullfile(image_filepath, 'ratingscale-01ment_content-danger.png');
ment_enjoy_scale                = fullfile(image_filepath, 'ratingscale-01ment_content-enjoy.png');
ment_heights_scale              = fullfile(image_filepath, 'ratingscale-01ment_content-heights.png');
ment_remember_scale             = fullfile(image_filepath, 'ratingscale-01ment_content-remember.png');
ment_tired_scale                = fullfile(image_filepath, 'ratingscale-01ment_content-tired.png');
like_scale                      = fullfile(image_filepath, 'ratingscale-02likeability.png');
sim_scale                       = fullfile(image_filepath, 'ratingscale-03similarity.png');


%% D. making output table ________________________________________________________
vnames = {'src_subject_id', 'session_id', 'param_counterbalance_ver','param_video_id',...
'param_trigger_onset', 'param_start_biopac',...
'event01_block_cue_type','event01_block_order','event01_block_cue_onset','event01_block_cue_stop','event01_block_cue_onset_biopac',...
'event02_video_filename', 'event02_video_onset','event02_video_stop','event02_video_onset_biopac',...
'event03_rating_displayonset','event03_rating_displaystop','event03_rating_RT','event03_rating_responseonset','event03_rating_displayonset_biopac','event03_rating_displayresponse_biopac','event03_rating_type',...
'param_end_instruct_onset', 'param_end_biopac', 'param_experiment_duration'};

vtypes = {  'double','double','double','double','double','double',...
'string','double','double','double','double',...
'string','double','double','double',...
'double','double','double','double','double','double','string',...
'double','double','double'};

T = table('Size', [size(design_file,1) size(vnames,2)], 'VariableNames', vnames, 'VariableTypes', vtypes);
T.src_subject_id(:)            = sub_num;
T.session_id(:)                = 3;
T.param_counterbalance_ver(:)             = sub_num;
T.param_video_id         = design_file.video_id;


%% E. Keyboard information _____________________________________________________
KbName('UnifyKeyNames');
p.keys.confirm                 = KbName('return');
p.keys.right                   = KbName('3#');
p.keys.left                    = KbName('1!');
p.keys.space                   = KbName('space');
p.keys.esc                     = KbName('ESCAPE');
p.keys.trigger                 = KbName('5%');
p.keys.start                   = KbName('s');
p.keys.end                     = KbName('e');

[id, name]                     = GetKeyboardIndices;
trigger_index                  = find(contains(name, 'Current Designs'));
trigger_inputDevice            = id(trigger_index);

keyboard_index                 = find(contains(name, 'AT Translated Set 2 Keyboard'));
keyboard_inputDevice           = id(keyboard_index);

%% F. fmri Parameters __________________________________________________________
TR                             = 0.46;
duration = 5;

% empty options for video Screen
shader = [];
pixelFormat = [];
maxThreads = [];

iteration = 0;
escape = 0;

% Use blocking wait for new frames by default:
blocking = 1;

% Default preload setting:
preloadsecs = [];
% Playbackrate defaults to 1:
rate=1;
%% H. Make Images Into Textures ________________________________________________
DrawFormattedText(p.ptb.window,sprintf('LOADING\n\n0%% complete'),'center','center',p.ptb.white );
HideCursor;
Screen('Flip',p.ptb.window);
instruct_filepath              = fullfile(main_dir, 'stimuli', 'instructions');
instruct_start                 = fullfile(instruct_filepath, 'start.png');
instruct_trigger               = fullfile(instruct_filepath, 'trigger.png');
instruct_end                   = fullfile(instruct_filepath, 'end.png');

    % preload CUE

    cue_image = dir(fullfile(main_dir, 'stimuli', 'cue', '*.png'));
    cue_tex = cell(length(cue_image),1);
    for c = 1:length(cue_image)
        cue_filename = fullfile(cue_image(c).folder, cue_image(c).name);
        cue_tex{c} = Screen('MakeTexture', p.ptb.window, imread(cue_filename));
    end

    % preload RATING
    rating_image = dir(fullfile(main_dir, 'stimuli', 'ratingscale', '*.png'));
    rating_tex = cell(length(rating_image),1);
    for r = 1:length(rating_image)
        rating_filename = fullfile(rating_image(r).folder, rating_image(r).name);
        rating_tex{r} = Screen('MakeTexture', p.ptb.window, imread(rating_filename));
    end
    rating_tex
    size(rating_tex)

    % instruction, actual texture

    for v = 1:length(video_metadata.video_name)
        DrawFormattedText(p.ptb.window,sprintf('LOADING\n\n%d%% complete', ceil(100*v/length(video_metadata.video_name))),'center','center',p.ptb.white);
        Screen('Flip',p.ptb.window);
    end

    start_tex       = Screen('MakeTexture',p.ptb.window, imread(instruct_start));
    trigger_tex       = Screen('MakeTexture',p.ptb.window, imread(instruct_trigger));
    end_tex       = Screen('MakeTexture',p.ptb.window, imread(instruct_end));



%% -----------------------------------------------------------------------------
%                              Start Experiment
% ______________________________________________________________________________

%% ______________________________ Instructions _________________________________
% Screen('TextSize',p.ptb.window,72);
% DrawFormattedText(p.ptb.window,'.','center',p.ptb.screenYpixels/2,255);
% Screen('Flip',p.ptb.window);

Screen('DrawTexture',p.ptb.window,start_tex,[],[]);
Screen('Flip',p.ptb.window);



%% _______________________ Wait for Trigger to Begin ___________________________
% 1) wait for 's' key, once pressed, automatically flips to fixation
% 2) wait for trigger '5'
DisableKeysForKbCheck([]);

WaitKeyPress(p.keys.start);
Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
    p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
Screen('Flip',p.ptb.window);


WaitKeyPress(p.keys.trigger);
T.param_trigger_onset(:) = GetSecs;
T.param_start_biopac(:)                   = biopac_linux_matlab(biopac, channel, channel.trigger, 1);

%% ___________________________ Dummy scans ____________________________
Screen('DrawTexture',p.ptb.window,trigger_tex,[],[]);
Screen('Flip',p.ptb.window);
WaitSecs(TR*6);


%% 0. Experimental loop _________________________________________________________
% block start
ment_order = 0;
%have a canonical cue cue_order     %shuffle it per participant
content_key = {'angry', 'calm', 'danger', 'enjoy', 'heights', 'remember', 'tired'};
random_idx = randperm(numel(content_key));
%content_shuffled = content_key(random_idx);


for blk = 1:length(unique(design_file.block_order))
blk
%% _____________________________ 1. Block cue (3s)
cue_to_show = design_file.judgment{3*(blk-1)+1};
blk_firstrow = trials_per_blk*(blk-1)+1;

if isequal(cue_to_show, 'mentalizing')
    cue_texture = cue_tex{1};
    ment_order = ment_order + 1;
    T.event01_block_cue_type(blk_firstrow:blk_firstrow+2) = 'mentalizing';
elseif isequal(cue_to_show, 'likeability')
    cue_texture = cue_tex{2};
    T.event01_block_cue_type(blk_firstrow:blk_firstrow+2) = 'likeability';
elseif isequal(cue_to_show, 'self_other')
    cue_texture = cue_tex{3};
    T.event01_block_cue_type(blk_firstrow:blk_firstrow+2) = 'similarity';
end

Screen('DrawTexture',p.ptb.window,cue_texture,[]);
T.event01_block_cue_onset_biopac(blk_firstrow:blk_firstrow+2) = biopac_linux_matlab(biopac, channel, channel.cue, 1);
T.event01_block_cue_onset(blk_firstrow:blk_firstrow+2) = Screen('Flip', p.ptb.window);
WaitSecs('UntilTime', T.event01_block_cue_onset(blk_firstrow) + 3);
biopac_linux_matlab(biopac, channel, channel.cue, 0);

T.event01_block_order(3*(blk-1)+1:3*(blk-1)+3) = blk;


%% ___________________________ videos of 5 sc
for t = 1:trials_per_blk % 1~3

trl = trials_per_blk*(blk-1) + t; % row
trl
movie_trl = T.param_video_id(trl); % 1~ 21



% video load
preloadsecs =[];
video_file      = fullfile(main_dir, 'stimuli', 'videos', video_metadata.video_name{movie_trl});
[movie, dur, fps, imgw, imgh] = Screen('OpenMovie', p.ptb.window, video_file, [], preloadsecs, [], pixelFormat, maxThreads);

totalframes = floor(fps * dur);
fprintf('Movie: %s  : %f seconds duration, %f fps, w x h = %i x %i...\n', video_metadata.video_name{movie_trl}, dur, fps, imgw, imgh);
i=0;
Screen('PlayMovie', movie, rate, 1, 1.0);
T.event02_video_onset(trl)         = GetSecs;
T.event02_video_onset_biopac(trl)  = biopac_linux_matlab(biopac, channel, channel.movie, 1);

while i<totalframes-1

    escape=0;
    [keyIsDown,secs,keyCode]=KbCheck;
    if (keyIsDown==1 && keyCode(p.keys.esc))
        % Set the abort-demo flag.
        escape=2;
        % break;
    end


    % Only perform video image fetch/drawing if playback is active
    % and the movie actually has a video track (imgw and imgh > 0):

    if ((abs(rate)>0) && (imgw>0) && (imgh>0))
        % Return next frame in movie, in sync with current playback
        % time and sound.
        % tex is either the positive texture handle or zero if no
        % new frame is ready yet in non-blocking mode (blocking == 0).
        % It is -1 if something went wrong and playback needs to be stopped:
        tex = Screen('GetMovieImage', p.ptb.window, movie, blocking);

        % Valid texture returned?
        if tex < 0
            % No, and there wont be any in the future, due to some
            % error. Abort playback loop:
            %  break;
        end

        if tex == 0
            % No new frame in polling wait (blocking == 0). Just sleep
            % a bit and then retry.
            WaitSecs('YieldSecs', 0.005);
            continue;
        end

        Screen('DrawTexture', p.ptb.window, tex, [], [], [], [], [], [], shader); % Draw the new texture immediately to screen:
        Screen('Flip', p.ptb.window); % Update display:
        Screen('Close', tex);% Release texture:
        i=i+1; % Framecounter:

    end % end if statement for grabbing next frame
end % end while statement for playing until no more frames exist

T.event02_video_stop(trl) = GetSecs;
biopac_linux_matlab(biopac,channel, channel.movie, 0);

Screen('Flip', p.ptb.window);
KbReleaseWait;

Screen('PlayMovie', movie, 0); % Done. Stop playback:
Screen('CloseMovie', movie);  % Close movie object:

% Release texture:
%         Screen('Close', tex);

% if escape is pressed during video, exit
if escape==2
    %break
end
v = design_file.video_id(trl);
T.event02_video_filename(trl) = video_metadata.video_name{v};

%% ___________________________________ 3. Judgement rating (5s)
if isequal(cue_to_show, 'mentalizing')

    rating_texture =  rating_tex{random_idx(ment_order)};
    T.event03_rating_type(trl) = content_key{random_idx(ment_order)};

elseif isequal(cue_to_show, 'likeability')
    rating_texture = rating_tex{8};
    T.event03_rating_type(trl) = 'likeability';

elseif isequal(cue_to_show, 'self_other')
    %cue_file = sim_scale
    rating_texture = rating_tex{9};
    T.event03_rating_type(trl) = 'similarity';
end

[display_onset, trajectory, RT, response_onset, biopac_displayonset, biopac_response] = judgement_rating(p, duration, rating_texture, biopac, channel);
T.event03_rating_displayonset(trl) = display_onset;

T.event03_rating_RT(trl) = RT;
T.event03_rating_responseonset(trl) = response_onset;
T.event03_rating_displayonset_biopac(trl) = biopac_displayonset;
T.event03_rating_response_biopac(trl) = biopac_response;

rating_trajectory{trl,1} = trajectory;



%% temporarily save file
 tmp_file_name = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub_num)), '_task-',taskname,'_TEMPbeh.csv' ]);
 writetable(T,tmp_file_name);
end
% Screen('Close', rating_texture);
end

%% ______________________________ End Instructions _________________________________
Screen('DrawTexture',p.ptb.window,end_tex,[],[]);
T.param_end_instruct_onset(:)             = Screen('Flip',p.ptb.window);
T.param_end_biopac(:)                     = biopac_linux_matlab(biopac, channel, channel.trigger, 0);
WaitKeyPress(KbName('e'));
T.param_experiment_duration(:) = T.param_end_instruct_onset(1) - T.param_trigger_onset(1);
Screen('Close');


%% _________________________ 8. save parameter _________________________________
% onset + response file
saveFileName = fullfile(sub_save_dir,[bids_string,'_beh.csv' ]);
repoFileName = fullfile(repo_save_dir,[bids_string,'_beh.csv' ]);
writetable(T,saveFileName);
writetable(T,repoFileName);

% trajectory
traj_saveFileName = fullfile(sub_save_dir,[bids_string,'_trajectory.mat' ]);
traj_repoFileName = fullfile(repo_save_dir,[bids_string,'_trajectory.mat' ]);
save(traj_saveFileName, 'rating_trajectory');
save(traj_repoFileName, 'rating_trajectory');

% ptb parameters
psychtoolbox_saveFileName = fullfile(sub_save_dir, [bids_string,'_psychtoolboxparams.mat' ]);
psychtoolbox_repoFileName = fullfile(repo_save_dir, [bids_string,'_psychtoolboxparams.mat' ]);
save(psychtoolbox_saveFileName, 'p');
save(psychtoolbox_repoFileName, 'p');

if biopac;  channel.d.close();  end
clear p; clearvars; Screen('Close'); close all; sca;



%end
close all;
    function WaitKeyPress(kID)
        while KbCheck(-3); end  % Wait until all keys are released.

        while 1
            % Check the state of the keyboard.
            [ keyIsDown, ~, keyCode ] = KbCheck(-3);
            % If the user is pressing a key, then display its code number and name.
            if keyIsDown

                if keyCode(p.keys.esc)
                    cleanup; break;
                elseif keyCode(kID)
                    break;
                end
                % make sure key's released
                while KbCheck(-3); end
            end
        end
    end

end
