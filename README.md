# gp-oxfordsync
Scripting to support automated migration of data off GP's promethion instrument

Data Transfer sync job will attempt to launch periodically (1/hr?)
- If another sync job is already running it will not attempt to run
- If transfer is blocked for more than 5 iterations send email

On each run
- Only inspect folders with names that match “LCSET-nnnnn”
- Check for any sample directory (SM-XXXXX) that has been updated in last 7 days

For each such sample directory sync to hydrogen location
- Checking the update date means we won’t try to sync ALL folders, only newish ones
- This logic assumes that a sample won’t get any additional data added after a week
- “Sync” will be by rsync, which will be set to
> - Never remove files from the destination
> - Over-write files on the destination if there is a source file with the same name/path but different contents
> - Not compare times since the clocks may be skewed
> 
- Each run will create a log file indicating which sample directories were synced

A cleanup script will be written which will
- Only inspect folders with names that match “LCSET-nnnnn”
- Check for any sample directory (SM-XXXXX) that has not been updated in 30 days
- Remove those sample directories.

Each run will create a log file of which directories were deleted and which directories will be deleted by next week’s run

One can exempt a directory from deletion by moving it to an experiment  folder with a name that doesn’t match “LCSET-nnnnn”
