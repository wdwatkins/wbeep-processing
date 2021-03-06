# Combine the resulting files from the parallel tasks in
# process_quantiles_by_hru.R into one file and push to S3.
# library(dplyr)
# library(tidyr)
# library(pryr)
library(data.table)
# ptm <- proc.time()
files_to_combine <- list.files(path = "grouped_quantiles", 
                               pattern = "total_storage_quantiles",
                               full.names = TRUE)
#gets daily data
message("Read in each HRU group of quantiles file to a list")
file_contents_list <- lapply(files_to_combine, feather::read_feather)
# print(proc.time() - ptm)
# ptm <- proc.time()
# print(pryr::object_size(file_contents_list))
# #check order of all  DOY columns by doing a logical compare
# #could throw in an arrange here 
# sample <- file_contents_list[[1]]$DOY
# checks <- sapply(X = file_contents_list, 
#                  FUN = function(x, sample) {all(x$DOY == sample)},
#                  sample = sample)
# print(proc.time() - ptm)
# ptm <- proc.time()
# stopifnot(all(checks))

message("Turn each HRU group of quantiles from list into single dataset")
combined_data <- do.call("rbind", file_contents_list)# %>%  
#   select(DOY, matches('^[0-9]*$')) %>% 
#   pivot_longer(cols = -DOY, names_to = "hruid",
#                values_to = "total_storage_quantiles")
# print(pryr::object_size(combined_data))
# print(proc.time() - ptm)

#NOTE: data.table package can modify objects in place!
#that's why there is no explicit assignments here
# setDT(combined_data)
# combined_data[, c("0%", "10%", "25%", "75%", "90%", "100%") := transpose(total_storage_quantiles)]
# combined_data[,total_storage_quantiles := NULL]

# Add -inf and +inf here since it will be the same for all 
message("Fix quantiles to add 0% and 100%")
original_quantiles <- tail(names(combined_data), -2)
combined_data <- as.data.table(combined_data)
combined_data[, "0%" := -Inf]
combined_data[, "100%" := Inf]
setcolorder(combined_data, c("hruid", "DOY", "0%",
                             original_quantiles,
                             "100%"))

message("Save quantiles `as all_quantiles.rds`")
saveRDS(combined_data, "all_quantiles.rds")
## manually push RDS file to S3
