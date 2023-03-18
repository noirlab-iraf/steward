#{ STEWARD -- The STEWARD suite of packages.

cl < "steward$lib/zzsetenv.def"
package	steward, bin = stewardbin$

task	somtlocal.pkg	= "somtlocal$somtlocal.cl"
task	soproto.pkg	= "soproto$soproto.cl"

clbye()
