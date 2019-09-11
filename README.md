# wbeep-processing
the processing behind the wbeep viz

## Building a release

There are four Jenkins jobs chained together, in this order:

`HRU to GeoJSON -> Tippecanoe tile creation -> model output processing -> tile join`

To build a release, cut the release in this repository with an appropriate vx.x.x tag.  Go to the `HRU to GeoJSON` job, and start it with the appropriate tier and tag.  The tag list should populate automatically.  The tier and tag will be passed along to the downstream jobs.  

For non-release changes to test that only affect downstream jobs, you can start the appropriate job and will pass the parameters downstream the same way.  

The `HRU to GeoJSON -> Tippecanoe tile creation` part of the pipeline can run parallel to the model output processing job in terms of dependencies; the pipeline is linear for now in the interest of making the Jenkins jobs simpler.  

## Building the percentiles

This happens very infrequently, so we currently have it as a manual step running on Yeti. Follow the steps below to execute.

#### First, setup Yeti for these calculations.

Load data and scripts onto Yeti (yeti.cr.usgs.gov, AD login). Include all 6 model component historic record files with the pattern `historic_[var name]_out.nc`). Also load all scripts needed (see list below). Lindsay used WinSCP to do this step. It took a long time (hours!).

* `reformat_ncdf_rds.R`, 
* `combine_historic_records.R`, 
* `process_quantiles_by_hru.R`, 
* `combine_hru_quantiles.R`, 
* `reformat_historic.slurm`, and 
* `model_input.slurm`. 

If you are a windows user, you may need to run `dos2unix reformat_historic.slurm` and `dos2unix model_input.slurm` first to make the line endings correct.

#### Now, execute the steps on Yeti.

1. Login to Yeti, `ssh user@yeti.cr.usgs.gov`
1. First we need to read and reformat the variable NetCDF files. This can be done in parallel by executing a slurm script. Run `sbatch reformat_historic.slurm` to initiate this. You can monitor their progress by running `squeue -u [username]`.
1. When the reformatting step is complete, there should be RDS files available for each of the 6 model variables. Now we need to combine them. Start an interactive session `sinteractive -A iidd -p normal -n 1 -t 03:00:00  --mem=120GB` & then start R, by entering `R`. Run `source("combine_historic_records.R")` to combine the data into one file. This step took about XX minutes. Close R using `q()` and don't save the workspace image.
1. When the step to combine the variables is complete, you should be able to see a file called `combined_variables.rds`. Now you can kick off the parallel job by running `sbatch model_input.slurm`. 
1. When that is complete, start an interactive session just as before and run `source("combine_hru_quantiles.R")`. Make sure to use `q()` to leave the R session. 

Note: You can cancel your interactive jobs by running `scancel -u [username]`. Note that this cancels all of your current jobs, which should just be this one job for this process. You won't want to run this if you are simultaneously running jobs for other projects.

That should be everything! The resulting quantiles RDS file should be available in the appropriate S3 bucket.
