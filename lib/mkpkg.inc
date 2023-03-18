# Global MKPKG definitions for the STEWARD packages.

$set XFLAGS	= "$(XFLAGS) -/I/opt/iraf/local/lib -p steward"
$set XVFLAGS	= "$(XVFLAGS) -p steward"
$set LFLAGS	= "$(LFLAGS) -p steward"

$ifeq (MACH, sparc) then
$include "steward$lib/mkpkg.sf.SUN4"
$else $ifeq (MACH, i386) then
$include "steward$lib/mkpkg.sf.I386"
$else $ifeq (MACH, f68881) then
$include "steward$lib/mkpkg.sf.SUN3"
$else $ifeq (MACH, ffpa) then
$include "steward$lib/mkpkg.sf.SUN3"
$else $ifeq (MACH, vms) then
$include "steward$lib/mkpkg.sf.VMS"
$end
