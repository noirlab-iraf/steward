include <error.h>
include "retmmt.h"

# T_RRETMMT.X - Code for the MMT Reticon format tape reader.
#
# MMT Reticon files can be read into a series of one dimensional IRAF
# images.  Each Reticon file parameter list is read and compared against
# the "disk_numbers" and "picture_numbers" lists.  Depending on the user's
# request, the header can be printed in long or short form, and an IRAF
# image can be created.


procedure t_rretmmt()

char	infile[SZ_FNAME], in_fname[SZ_FNAME],
	outfile[SZ_FNAME],
	file_list[SZ_LINE], disk_list[SZ_LINE], pic_list[SZ_LINE]
int	lenlist, nf, ndisk, npic, file_number, junk, stat
pointer	sp, cp, list

bool	clgetb()
char	clgetc()
int	btoi(), mtfile(), strlen(), fntlenb(), fntgfnb()
int	getdatatype(), decode_ranges(), get_next_number()
int	read_retmmt()
long	clgetl()
pointer	fntopnb()

errchk	smark, salloc

begin
	# Allocate space for the control parameter descriptor structure

	call smark (sp)
	call salloc (cp, LEN_CP, TY_STRUCT)

	# Get parameters from the cl.

	call clgstr ("reticon_file", infile, SZ_FNAME)
	LONG_HEADER(cp) = long (btoi (clgetb ("long_header")))

	# If an output image is to be written, get output data type
	# and root output data file.

	MAKE_IMAGE(cp) = long (btoi (clgetb ("make_image")))
	if (MAKE_IMAGE(cp) == YES) {
	    call clgstr ("iraf_file", outfile, SZ_FNAME)
	    OVERWRITE(cp) = long (btoi (clgetb ("overwrite")))
	    START_NUMBER(cp) = clgetl ("start_number")
	    DATA_TYPE(cp) = long (getdatatype (clgetc ("data_type")))
	    if (DATA_TYPE(cp) == ERR)
		DATA_TYPE(cp) = TY_REAL
	}

	# Compute the number of files to be converted

	if (mtfile (infile) == YES) {
	    list = NULL
	    if (infile[strlen (infile)] != ']')
		call clgstr ("file_list", file_list, SZ_LINE)
	    else
		call strcpy ("1", file_list, SZ_LINE)
	} else {
	    list = fntopnb (infile, YES)
	    lenlist = fntlenb (list)
	    if (lenlist > 0) {
		call sprintf (file_list, SZ_LINE, "1-%d")
		    call pargi (lenlist)
	    } else
		call sprintf (file_list, SZ_LINE, "0")
	}

	# Decode the ranges

	if (decode_ranges (file_list, FRANGE(cp), MAX_RANGES, nf) == ERR)
	    call error (1, "T_RRETMMT:  Illegal file number list")
	call clgstr ("disk_numbers", disk_list, SZ_LINE)
	if (decode_ranges (disk_list, DRANGE(cp), MAX_RANGES, ndisk) == ERR)
	    call error (1, "T_RRETMMT:  Illegal disk number list")
	call clgstr ("picture_numbers", pic_list, SZ_LINE)
	if (decode_ranges (pic_list, PRANGE(cp), MAX_RANGES, npic) == ERR)
	    call error (1, "T_RRETMMT:  Illegal picture number list")

	# Read successive RETICON files, convert and write into a numbered
	# succession of output IRAF files

	NFILES(cp) = nf
	SEQ_NUMBER(cp) = 0
	file_number = 0
	while (get_next_number (FRANGE(cp), file_number) != EOF) {

	    # Get input file name

	    if (list != NULL)
		junk = fntgfnb (list, in_fname, SZ_FNAME)
	    else {
		call strcpy (infile, in_fname, SZ_FNAME)
		if (infile[strlen (infile)] != ']') {
		    call sprintf (in_fname[strlen (in_fname) + 1], SZ_FNAME,
				"[%d]")
			call pargi (file_number)
		}
	    }

	    # Convert the Reticon file to an IRAF file.
	    # If EOT is reached, then exit.
	    # If an error is detected, then print a warning and
	    # continue with the next file.
	    # Any errors which are returned to this present routine are fatal.

	    iferr (stat = read_retmmt (in_fname, outfile, cp))
		call erract (EA_FATAL)
	    if (stat == EOF)
		break
	}

	if (list != NULL)
	    call fntclsb (list)
	call sfree (sp)
end
