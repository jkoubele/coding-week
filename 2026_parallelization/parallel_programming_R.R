##### Install packages ####

#install.packages("parallel") # build-in, no install should be needed
install.packages("future")
install.packages("furrr")
install.packages("tictoc")


######## Setup ########

library(parallel)
library(future) # combines purrr functional programming tools with future package to run mapping functions in parallel
library(furrr)   # parallel version of purrr's map() functions
library(tictoc) # Timing: tic() / toc()


# Number of cores on machine
detectCores()
n_cores <- detectCores() - 2 # leave 1-2 cores free for OS
n_cores



######## parallel package ########

#### mclapply example ####

# Function that takes ~0.5 seconds
slow_function <- function(x) {
  Sys.sleep(0.5) # Suspend execution of R expressions for a specified time interval
  return(x^2)
}

inputs <- 1:30

# Serial
tic("Serial: lapply")
results_serial <- lapply(inputs, slow_function)
toc()

# Parallel
tic("Parallel: mclapply")
results_parallel <- mclapply(inputs, slow_function, mc.cores = n_cores)
toc()

tic("Parallel: parLapply")
cl <- makeCluster(n_cores)
clusterExport(cl, "slow_function") # Export the function to the cluster
results_parallel_parLapply <- parLapply(cl, inputs, slow_function)
stopCluster(cl) # Stop the cluster
toc()


#### parLapply example ####

# For each matrix compute for every row: mean, standard deviation, min, max
# Return the row with the highest mean
# Each matrix is processed independently: embarrassingly parallel

n_matrices <- 100   # number of matrices
n_rows     <- 1000  # rows per matrix
n_cols     <- 500   # columns per matrix

# Function: compute row-wise statistics for one matrix, return top row
process_matrix <- function(matrix_id) {
  
  set.seed(matrix_id)  # so results are reproducible and comparable
  
  # Generate a random matrix
  m <- matrix(rnorm(n_rows * n_cols), nrow = n_rows, ncol = n_cols)
  
  # Compute row-wise summary statistics
  row_means <- rowMeans(m)
  row_sds   <- apply(m, 1, sd)
  row_mins  <- apply(m, 1, min)
  row_maxs  <- apply(m, 1, max)
  
  # Find the row with the highest mean
  best_row  <- which.max(row_means)
  
  list(
    matrix_id    = matrix_id,
    best_row     = best_row,
    best_row_mean = row_means[best_row],
    overall_mean = mean(row_means),
    overall_sd   = mean(row_sds)
  )
}


# Serial
tic("Serial: matrix statistics")
results_serial <- lapply(1:n_matrices, process_matrix)
toc()

# Parallel with mclapply
tic("Parallel mclapply: matrix statistics")
results_par_mc <- mclapply(1:n_matrices, process_matrix, mc.cores = n_cores)
toc()

# Parallel with parLapply
# Requires explicit cluster creation, variable export, and cleanup
cl <- makeCluster(n_cores) # cluster creation
clusterExport(cl, c("n_rows", "n_cols")) # Workers are fresh R sessions —> they don't know about our variables -> Must export everything the function needs
tic("Parallel parLapply: matrix statistics")
results_par_cl <- parLapply(cl, 1:n_matrices, process_matrix)
toc()
stopCluster(cl)  # always stop the cluster when done!





######## future package ########

# furrr is a parallel drop-in for purrr's map() functions
# The key advantage: you write standard map() code, then switch to parallel
# by changing just ONE line (the plan()).
# This makes your code portable: same code runs locally AND on a cluster

# Override any system restriction on mc.cores (workstation has mc.cores option set to 1, which is overriding the physical core count)
options(mc.cores = parallel::detectCores() - 2)

n_cores <- parallelly::availableCores() 
n_cores


# Run serially
plan(sequential)

tic("furrr sequential: matrix statistics")
results_seq <- future_map(1:n_matrices, process_matrix)
toc()

# Run in parallel (only need to change one line)
plan(multisession, workers = n_cores)

tic("furrr multisession: matrix statistics")
results_par <- future_map(1:n_matrices, process_matrix)
toc()


# --- On a cluster: only this one line changes! ---
# plan(cluster, workers = c("node1", "node2", "node3"))
# future_map(1:n_matrices, process_matrix)  # exact same code, runs on cluster



######## Overhead ########

# Amdahl's Law in action: if the task is too small, the overhead of spawning and communicating with workers costs more than you save

trivial_function <- function(x) x^2

input <- 1:1000

# Serial
tic("Serial: trivial function x1000")
res_serial <- lapply(input, trivial_function)
toc()

# Parallel
tic("Parallel: trivial function x1000")
res_parallel <- mclapply(input, trivial_function, mc.cores = n_cores)
toc()


