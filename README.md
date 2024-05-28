# Quantiser

This repo has algorithms inspired by [A simple method for color quantization: octree quantization](https://dl.acm.org/doi/10.5555/90767.90833) 
appearing in Graphics Gems (Volume IV, I think).

The approach taken here **does not** actually use an octreee data structure. Instead a `Dictionary` is used because many modern languages 
natively support an efficient `Dictionary` data type. 

The inspiration taken from the earlier method is arranging for the quantisation bins to be recursively nested, such that re-quantisation during 
an input sequence pass is efficient, with no requirement to restart the sequence. This is a somewhat "dynamic programming" approach because it 
makes use of overlap in sub problems.

The algorithm is fairly general. It could be used to find an image colour map. More generally, it can quantise any stream of input data in to 
some fixed number of bins, growing the bin sizes as necessary to make the data fit.

## Possible extension

The provided implementation doubles the quanta size each time the quanta limit is exceeded. Possible quanta sizes are the powers of 2: 
`1, 2, 4, 8, 16, 32, …`

However, it should be possible to change this search algorithm to consider some small set of quanta size factors such as `{2, 3, 5}`. Doing so 
would allow quanta sizes of: `2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16, 18, 20, 24, 25, …`

