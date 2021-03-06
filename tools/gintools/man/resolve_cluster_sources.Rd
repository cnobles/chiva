% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/resolve_cluster_sources.R
\name{resolve_cluster_sources}
\alias{resolve_cluster_sources}
\title{Resolve primary sources from clusters with multiple souce nodes.}
\usage{
resolve_cluster_sources(red.sites, graph)
}
\arguments{
\item{red.sites}{GRanges object which has been reduced to single nt positions
and contains the revmap from the original GRanges object. The object must
also contain a column for cluster membership (clusID) and a column for
abundance (fragLengths).}

\item{graph}{a directed graph built from the red.sites object. Each node
corresponds to a row in the red.sites object.}

\item{bias}{either "upsteam" or "downstream", designating which position to
choose if other decision metrics are tied.}
}
\description{
Given a list of unique integration site positions (reduced
GRanges object) and a directed graph of connected components, this function
identifies clusters where multiple source nodes exist and then identifies
which source should be considered the primary source node, first based on
abundance and then
}
\details{
\code{resolve_cluster_sources} returns a graph where each cluster only
has a single primary source node.
}
\examples{
gr <- gintools:::generate_test_granges(stdev = 3)
red.sites <- reduce(
  flank(gr, -1, start = TRUE),
  min.gapwidth = 0L,
  with.revmap = TRUE)
red.sites$siteID <- seq_along(red.sites)
revmap <- as.list(red.sites$revmap)
red.sites$abundance <- lengths(revmap)
red.hits <- GenomicRanges::as.data.frame(
  findOverlaps(red.sites, maxgap = 0L, drop.self = TRUE))
red.hits <- red.hits \%>\%
  mutate(q_pos = start(red.sites[queryHits])) \%>\%
  mutate(s_pos = start(red.sites[subjectHits])) \%>\%
  mutate(q_abund = red.sites[queryHits]$abundance) \%>\%
  mutate(s_abund = red.sites[subjectHits]$abundance) \%>\%
  mutate(strand = unique(strand(
    c(red.sites[queryHits], red.sites[subjectHits])))) \%>\%
  mutate(is.upstream = ifelse(
    strand == "+",
    q_pos < s_pos,
    q_pos > s_pos)) \%>\%
  mutate(keep = q_abund > s_abund) \%>\%
  mutate(keep = ifelse(
    q_abund == s_abund,
    is.upstream,
    keep)) \%>\%
  filter(keep)
g <- make_empty_graph(n = length(red.sites), directed = TRUE) \%>\%
  add_edges(unlist(mapply(
    c, red.hits$queryHits, red.hits$subjectHits, SIMPLIFY = FALSE)))
red.sites$clusID <- clusters(g)$membership
g <- connect_satalite_vertices(red.sites, g, gap = 2L, "upstream")
red.sites$clusID <- clusters(g)$membership
g <- break_connecting_source_paths(red.sites, g, "upstream")
red.sites$clusID <- clusters(g)$membership
g <- connect_adjacent_clusters(red.sites, g, gap = 5L, "upstream")
red.sites$clusID <- clusters(g)$membership

resolve_cluster_sources(red.sites, g, "upstream")

}
\author{
Christopher Nobles, Ph.D.
}
