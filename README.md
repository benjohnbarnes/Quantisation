This repo has algorithms inspired by [A simple method for color quantization: octree quantization](https://dl.acm.org/doi/10.5555/90767.90833) 
appearing in Graphics Gems (IV, I think). 

The approach taken here **does not** actually use an octreee data structure at all. Instead a `Set` is used because many modern languages natively
support an efficient `Set` data type. The inspiration taken from the earlier method is arranging for the quantisation bins to be recursively nested,
such that re-quantisation during an input sequence pass is efficient, with no requirement to restart the sequence. This is a somewhat "dynamic 
programming" approach because it makes use of overlap in sub problems.

The algorithm is fairly general. It could be used to find an image colour map. More generally, it can quantise any stream of input data in to some
fixed number of bins, growing the bin sizes as necessary to make the data fit.

## Possible extensions

The provided implementation doubles the bin size each time the bin limit is exceeded. However, extensions are suggested to allow other factors to be
used (eg, `{2, 3, 5}`), such that tighter binnings can be discovered.

The provided implementation does not try to pick a most representative quanitised element for a bin. However, extensions are suggested to track
arbitrary statistics about binned elements such that a better representative element for a bin can be chosen.
