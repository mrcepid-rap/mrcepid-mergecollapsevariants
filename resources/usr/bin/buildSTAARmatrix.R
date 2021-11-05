#!/usr/bin/Rscript --vanilla

# Load required libraries
library(data.table)
library(Matrix)

# Read in inputs. They are:
# 1. [1] Samples file (*.psam) – the rows of our final matrix
# 2. [2] Our list of variants – the columns of our final matrix
# 3. [3] list of matrix files – the cells in our final matrix
# 4. [4] prefix – the prefix for the name of the final file
args = commandArgs(trailingOnly = T)
samples_file = args[1]
variants_file = args[2]
matrix_list = args[3]
file_prefix = args[4]

# Process the samples file:
samples <- fread(samples_file)
samples[,row:=.I] # Set a dummy variable for row number so that we can index it during matrix creation
setnames(samples,"#IID","sampID") # just set a column name for sample ID that is more 'compatible' that #IID
samples[,sampID:=as.character(sampID)] # Make sure to set as a character - typically gets read as a integer

# Process the variants file:
variants = fread(variants_file)
variants[,column:=.I] # Set a dummy variable for column number so that we can index it during matrix creation
setnames(variants,"ID","varID") # just set a column name for variant ID that is more 'readable' that #ID
variants[,varID:=paste0("chr",varID)] # Need to append 'chr' to each variant ID since that's how it's stored in our matrix

# Initialise the correct sized lgCMatrix - a sparseMatrix from the Matrix package
# Matrix will be n. samples x n. variants
# We initial the final cell [n.sample][n.variants]  = 1 so that it knows we want a numeric matrix. All other cells are
# still "empty" here
gt_matrix = sparseMatrix(i = nrow(samples), j = nrow(variants), x = 1)
gt_matrix[nrow(samples),nrow(variants)] = 0 # Finalise the matrix to get rid of the dummy point I made above:

# Just set rownames to their actual values
rownames(gt_matrix) <- samples[,sampID]
colnames(gt_matrix) <- variants[,varID]

# Now we are iterating through all of the matrix files from the matrix list to fill in the cells of our matrix:
matrix_files <- fread(matrix_list, header = F)
for (i in 1:nrow(matrix_files)) {

    # Grab the i indexed file from the "data.table" I fread in above. V1 is just the default name for the first column
    # which I never set as a real name because I am lazy
    sparse_matrix = matrix_files[i,V1]

    # Now read in the actual sparse matrix and set column names that are the same as in our big matrix (gt_matrix)
    var_matrix = fread(sparse_matrix, header = F)
    setnames(var_matrix,names(var_matrix),c("sampID","varID","gt"))
    var_matrix[,sampID:=as.character(sampID)] # make sure sampID is a character as above

    # These two lines just add the correct row and column [i][j] value to each row in the var_matrix
    var_matrix <- merge(var_matrix, samples[,c("sampID","row")], by = "sampID") # add indexed row (sample)
    var_matrix <- merge(var_matrix, variants[,c("varID","column")], by = "varID") # add indexed column (variant)

    # set genotype according to gt field in the original matrix as a numeric
    var_matrix[,gt.numeric:=ifelse(gt == "0/1", 1,
                            ifelse(gt == "1/1", 2,0))]

    # Now we just go through every row and set [i][j] in gt_matrix according to the per-vcf matrix
    for (j in 1:nrow(var_matrix)) {
      gt_matrix[var_matrix[j,row],var_matrix[j,column]] = var_matrix[j,gt.numeric]
    }
}

# And save the final file to our AWS instance.
saveRDS(gt_matrix, paste0("/test/", file_prefix, ".STAAR.matrix.rds"))

