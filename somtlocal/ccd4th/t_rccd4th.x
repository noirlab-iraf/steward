include <error.h>
include <mach.h>
include "ccd4th.h"

# T_RCCD4TH.X - Code for the CCD FORTH format tape reader.
#
# CCD FORTH pictures can be read into a series of two dimensional IRAF images.
# Each CCD FORTH header is read and compared against the "picture_numbers" list.
# Depending on the user's request, the header can be printed in long or short
# form, and an IRAF image can be created.

define DEFAULT_BUF_SIZE     0


procedure t_rccd4th()

pointer sp, cp, ccd, pc4b
char	forth_file[SZ_PATHNAME], pic_numbers[SZ_LINE]
int	file_number, fd, sz_buffer, nskip, skipped
int	pictures[3,MAX_RANGES], npics, npics_read  # These should be 'long',
						   # but ranges.x routines in
						   # xtools requires 'int'.
bool	clgetb(), is_in_range()
char	clgetc()
int	clgeti(), mtfile(), mtopen(), strlen(), btoi(), decode_ranges()
int	getdatatype(), read()
long	clgetl()

begin
	# allocate space for the control parameter descriptor structure
	# and the program data structure
	
	call smark (sp)
	call salloc (cp, LEN_CP, TY_STRUCT)
	call salloc (ccd, LEN_CCD, TY_STRUCT)

	# Get parameters from the cl and generate the input file name.	If
	# the input file is a general tape device, append the file_number
	# suffix.

	call clgstr ("forth_file", forth_file, SZ_FNAME)
	if (mtfile (forth_file) == YES
		&& forth_file[strlen (forth_file)] != ']') {
	    file_number = clgeti ("file_number")
	    call sprintf (forth_file[strlen (forth_file)+1], SZ_PATHNAME,
			"[%d]")
		call pargi (file_number)
	}

	LONG_HEADER(cp) = long (btoi (clgetb ("long_header")))

	call clgstr ("picture_numbers", pic_numbers, SZ_LINE)
	if (decode_ranges (pic_numbers, pictures, MAX_RANGES, npics) == ERR)
	    call error (1, "Error in picture_numbers specifications")

	nskip = clgeti ("skip_npictures")

	# If an output image is to be written, get output data type and
	# root output data file.

	MAKE_IMAGE(cp) = long (btoi (clgetb ("make_image")))
	if (MAKE_IMAGE(cp) == YES) {
	    call clgstr ("iraf_file", IRAF_FILE(cp), SZ_FNAME)
	    OVERWRITE(cp) = long (btoi (clgetb ("overwrite")))
	    OFFSET(cp) = clgetl ("offset")
	    DATA_TYPE(cp) = long (getdatatype (clgetc ("data_type")))
	    if (DATA_TYPE(cp) == ERR)
		DATA_TYPE(cp) = TY_REAL
	}

	fd = mtopen (forth_file, READ_ONLY, DEFAULT_BUF_SIZE)
	sz_buffer = SZB_FORTH_RECORD / SZB_CHAR

	# Allocate input buffer in units of long integers
	call salloc (pc4b, sz_buffer * SZ_LONG, TY_LONG)

	skipped = 0
	npics_read = 0
	while (npics_read < npics) {

	    # Read CCD FORTH record into buffer.  Unpack unsigned bytes into
	    # long integer array.
	    if (read (fd, Meml[pc4b], sz_buffer) == EOF) {
		call printf ("CCD FORTH tape at End of File\n")
		break
	    } else {
		call achtbl (Meml[pc4b], Meml[pc4b], SZB_FORTH_RECORD)
		call dg_uint_to_long (Meml[pc4b], HEADER_NO_OFFSET, HEADER_NO(ccd))
		if (HEADER_NO(ccd) != 0) {
		    # A header has been read
		    if (skipped < nskip) {
			skipped = skipped + 1
			next
		    }
		    call dg_uint_to_long (Meml[pc4b], PICTURE_N_OFFSET, PICTURE_N(ccd))

		    iferr {
			if (is_in_range (pictures, int (PICTURE_N(ccd)))) {
			    call ccd_process_picture (fd, Meml[pc4b], cp, ccd)
			    npics_read = npics_read + 1
			    call flush (STDOUT)
			}
		    } then {
			call erract (EA_WARN)
			next
		    }
		}
	    }
	}

	call close (fd)
	call sfree (sp)
end
