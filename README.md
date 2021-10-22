# RaymarchShader
Ray marching shader in cg

# It works but isn't finished
I am working on making the rendering more changeable/fixing materials etc, and cleaning up the codebase.

\- Erik


| `FastMath.cginc`          | faster math functions                         | ok? |
| -------------------       | ---------------------                         | --- |
| `RayMarchLib.cginc`       | contains the core renderer + extra stuff      |     |
| -------------------       | ---------------------                         | --- |
| `RayMarchLib.h`           | renderer header file                          |     |
| -------------------       | ---------------------                         | --- |
| `RayMarchUtil.cginc`      | helper stuff for RayMarchLib                  |     |
| -------------------       | ---------------------                         | --- |
| `RayTraceFunctions.cginc` | ray tracing functions                         | yes |
| -------------------       | ---------------------                         | --- |
| `SdfFunctions.cginc`      | sdf functions to be used by the final shader  | yes |
| -------------------       | ---------------------                         | --- |
| `SdfMath.cginc`           | helper stuff for sdf, eg blend materials      |     |
| -------------------       | ---------------------                         | --- |
| `Transforms.cginc`        | transform space in diffrent ways              | yes |
| -------------------       | ---------------------                         | --- |
| `Noise.cginc`             | generate noise                                | yes |
| -------------------       | ---------------------                         | --- |
| `sdf.cginc`               | depricated and should merge with sdffunctions | del |
