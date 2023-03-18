include <error.h>
include "ccd4th.h"

# CCD_PROCESS_PICTURE - Process header and read records of data.

procedure ccd_process_picture (fd, c4b, cp, ccd)

int	fd			# file descriptor
long	c4b[ARB]		# buffer of unpacked CCD header - one byte/long
pointer cp			# pointer to control parameter data structure
pointer ccd			# pointer to program data structure

char	out_fname[SZ_FNAME]	# name of output file

int	strlen(), imaccess()

begin
	iferr (call ccd_convert_header (c4b, ccd)) {
	    call erract (EA_WARN)
	    return
	}

	call ccd_print_header (ccd, LONG_HEADER(cp))
	if (MAKE_IMAGE(cp) == YES) {
	    # Make the IRAF image name.
	    call strcpy (IRAF_FILE(cp), out_fname, SZ_FNAME)
	    call sprintf (out_fname[strlen (out_fname) + 1], SZ_FNAME, ".%04d")
		call pargl (PICTURE_N(ccd) + OFFSET(cp))
	    
	    # Check if image exists and should be overwritten.
	    if (imaccess (out_fname, 0) == YES) {
		if (OVERWRITE(cp) == YES)
		    call imdelete (out_fname)
		else {
		    call eprintf ("image name '%s' already exists\n")
			call pargstr (out_fname)
		    call erract (EA_WARN)
		    return
		}
	    }

	    # Make the image.
	    iferr (call ccd_rw_picture (fd, ccd, out_fname, DATA_TYPE(cp))) {
		call erract (EA_WARN)
		return
	    }
	}
end
