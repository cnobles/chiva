#' Identify intersection between multiple vectors
#'
#' \code{vintersect} returns a single vector from input vectors containing
#' intersecting values from the input vectors. `limit` can be used to specify an
#' observational limit to include values in the output. 
#'
#' @description Similar to intersect, `vintersect` identifies values that 
#' occure in each vector. The similar code would be to identify intersecting 
#' values between two vectors and then look for the intersect with a third 
#' vector and so on. Rather, all vectors are input at the same time and 
#' intersecting values are returned. The `limit` parameter can define the 
#' minimum number of observations of a value before it is returned. An example
#' would be if you wanted all values that occur in 2 out of 3 vectors (as in the
#' example presented below), for this the `limit` would be set to 2 and you 
#' would supply all three vectors. The returned values will be all values 
#' present in at least 2 of the vectors. By default, the limit is set to the 
#' number of input vectors to return only values intersecting in all vectors.
#'
#' @usage
#' vintersect(..., limit = NULL)
#'
#' @param ... a series of vectors to compare against eachother, either 
#' independently input or in a list.
#' @param limit integer The number of minimum observations of a single value 
#' before it is included in the output. Defaults to the number of input vectors,
#' but can be reduce to increase the number of returned values.
#'
#' @examples
#' A <- c(1,2,3)
#' B <- c(2,3,4)
#' C <- c(3,4,5)
#' vintersect(A, B, C)
#' vintersect(A, B, C, limit = 2)
#'
#' @author Christopher Nobles, Ph.D.
#' @export

vintersect <- function(..., limit = NULL){
  if(is.list(...)){
    v <- c(...)
  }else{
    v <- list(...)
  }
  stopifnot(all(sapply(v, is.vector)))
  if(is.null(limit)) limit <- length(v)
  stopifnot(limit <= length(v))
  cnt <- table(unlist(v))
  cnt <- cnt[cnt >= limit]
  return(names(cnt))
}
