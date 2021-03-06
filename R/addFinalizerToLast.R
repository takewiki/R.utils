###########################################################################/**
# @RdocDefault addFinalizerToLast
#
# @title "Modifies .Last() to call 'finalizeSession()"
#
# \description{
#   @get "title" \emph{before} calling the default \code{.Last()} function.
#
#   Note that \code{.Last()} is \emph{not} guaranteed to be called when
#   the \R session finished.  For instance, the user may quit \R by calling
#   \code{quit(runLast=FALSE)} or run R in batch mode.
#
#   Note that this function is called when the R.utils package is loaded.
# }
#
# @synopsis
#
# \arguments{
#  \item{...}{Not used.}
# }
#
# \value{
#   Returns (invisibly) @TRUE if \code{.Last()} was modified,
#   otherwise @FALSE.
# }
#
# @author
#
# \seealso{
#   @see "onSessionExit".
# }
#
# @keyword programming
#*/###########################################################################
setMethodS3("addFinalizerToLast", "default", function(...) {
  # Modify existing .Last() or create a new one?
  if (exists(".Last", mode="function")) {
    # A) Modify
    .Last <- get(".Last", mode="function")

    # Already has finalizeSession()?
    if (identical(attr(.Last, "finalizeSession"), TRUE)) {
      # And a version from R.utils v0.8.5 or after?
      ver <- attr(.Last, "finalizeSessionVersion")
      if (!is.null(ver) && compareVersion(ver, "0.8.5") >= 0) {
        # ...then everything is fine.
        return(invisible(FALSE))
      }

      # Otherwise, overwrite old buggy version.
    } else {
      # Rename original .Last() function
      env <- globalenv(); # To please R CMD check
      assign(".LastOriginal", .Last, envir=env)
    }

    # Define a new .Last() function
    .Last <- function(...) {
      tryCatch({
        if (exists("finalizeSession", mode="function"))
          finalizeSession()
        if (exists(".LastOriginal", mode="function")) {
          .LastOriginal <- get(".LastOriginal", mode="function")
          .LastOriginal()
        }
      }, error = function(ex) {
        message("Ignoring error occured in .Last(): ", as.character(ex))
      })
    }
  } else {
    # B) Create a new one
    .Last <- function(...) {
      tryCatch({
        if (exists("finalizeSession", mode="function"))
          finalizeSession()
      }, error = function(ex) {
        message("Ignoring error occured in .Last(): ", as.character(ex))
      })
    }
  }
  attr(.Last, "finalizeSession") <- TRUE
  attr(.Last, "finalizeSessionVersion") <- packageDescription("R.utils")$Version
  environment(.Last) <- globalenv()

  # Store it.
  env <- globalenv(); # To please R CMD check
  assign(".Last", .Last, envir=env)

  invisible(FALSE)
}, private=TRUE)
