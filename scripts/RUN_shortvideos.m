5% 1. grab participant number ___________________________________________________

sub_prompt = 'PARTICIPANT (in raw number form, e.g. 1, 2,...,98): ';
sub_num = input(sub_prompt);
b_prompt = 'BIOPAC YES=1 NO=0 : ';
biopac = input(b_prompt);

debug = 0; %DEBUG_MODE = 1, Actual_experiment = 0



% DOUBLE CHECK MSG ______________________________________________________________
%% A. Directories ______________________________________________________________
task_dir                        = pwd;
repo_dir                        = fileparts(fileparts(task_dir));
ses_num = 3; run_num = 1;
repo_save_dir = fullfile(repo_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)),...
    'task-shortvideos');
bids_string                     = [strcat('sub-', sprintf('%04d', sub_num)), ...
    strcat('_ses-',sprintf('%02d', ses_num)),...
    strcat('_task-shortvideos')];
repoFileName = fullfile(repo_save_dir,[bids_string,'*_beh.csv' ]);

% 3. if so, "this run exists. Are you sure?" ___________________________________
if isempty(dir(repoFileName)) == 0
    RA_response = input(['\n\n---------------ATTENTION-----------\nThis file already exists in: ', repo_save_dir, '\nDo you want to overwrite?: (YES = 999; NO = 0): ']);
    if RA_response ~= 999 || isempty(RA_response) == 1
        error('Aborting!');
    end
end
% ______________________________________________________



shortvideos(sub_num, biopac, debug)
