include <imhdr.h>
include <mach.h>
include "retmmt.h"

define NREC	Meml[nrec+$1-1]		# number of data records, 0 is end
define LREC	Meml[lrec+$1-1]		# length of data records in 16-bit words
					#   convert to chars
define MSEC_PER_MIN	60000		# milliseconds per minute
define MSEC_PER_TENTHS    100		# milliseconds per tenths of seconds

# READ_RETMMT.X - Read an MMT Reticon tape and convert it to an IRAF image,
#                 return EOF when at end of tape, or ERR if no data.

int procedure read_retmmt (ret_fname, iraf_root, cp)

char	ret_fname[ARB]	# input Reticon file name
char	iraf_root[ARB]	# output IRAF root file name
pointer	cp		# pointer to control parameter structure

bool	in_range
char	str[80], iraf_fname[SZ_FNAME]
int	ret_fd, stat, len, i, j, noff, beam_base
long	type, nchars, offset, count, data_off
pointer	sp, dret, ret, nrec, lrec, dat, im, pt

bool	is_in_range()
int	mtopen(), read(), strlen(), imaccess()
pointer immap(), impl1l()

define	exit_	91

begin
	# Allocate space for the program data structure
	call smark (sp)
	call salloc (dret, LEN_DRET, TY_DOUBLE)
	call salloc (ret, LEN_RET, TY_STRUCT)
	call salloc (dat, TOTLEN * SZ_LONG, TY_LONG)
	call salloc (nrec, MAX_RANGES, TY_LONG)
	call salloc (lrec, MAX_RANGES, TY_LONG)

	# Open input Reticon file
	ret_fd = mtopen (ret_fname, READ_ONLY, 0)

	stat = read (ret_fd, Meml[dat], LEN_ID_REC / SZB_CHAR)
	if (stat == EOF)
	    call printf ("End of data\n")
	else {
	    len = stat
	    call achtbl (Meml[dat], Meml[dat], len * SZB_CHAR)
	    call dg_uint_to_long (Meml[dat], TYPE_OFFSET, type)
	    if (type == LABEL_TYPE) {
		call dg_ubyte_to_long (Meml[dat], TAPE_LABEL_OFFSET, count)
		if (count > SZ_LABEL)
		    count = SZ_LABEL
		call dg_char_to_char (Meml[dat], TAPE_LABEL_OFFSET + 1,
			int (count), LABEL(ret))
		call eprintf ("%s:  tape label record, label = \"%s\"\n")
		    call pargstr (ret_fname)
		    call pargstr (LABEL(ret))
		if (LONG_HEADER(cp) == YES)
		    call eprintf ("\n")
		stat = ERR
	    } else if (type == HEADER_TYPE) {
		call dg_ubyte_to_long (Meml[dat], IFILE_ID_OFFSET, count)
		if (count > SZ_TEXT_FIELD)
		    count = SZ_TEXT_FIELD
		call dg_char_to_char (Meml[dat], IFILE_ID_OFFSET + 1,
			int (count), FILE_ID(ret))
		call strcpy (FILE_ID(ret), LABEL(ret), SZ_LABEL)
		nchars = 0
		do i = 1, MAX_RANGES {
		    call dg_uint_to_long (Meml[dat], NREC_OFFSET(i),
					  NREC(i))
		    if (NREC(i) == 0) {
			break
		    }
		    call dg_uint_to_long (Meml[dat], LREC_OFFSET(i),
					  LREC(i))
		    LREC(i) = 2 * LREC(i) / SZB_CHAR   # convert to # characters
		    nchars = nchars + NREC(i) * LREC(i)
		}
		if (nchars > TOTLEN) {
		    call eprintf ("%s:  too many data points, = %d chars\n")
			call pargstr (ret_fname)
			call pargl (nchars)
		    stat = ERR
		} else {
		    offset = 0
		    do i = 1, MAX_RANGES {
			if (NREC(i) == 0)
			    break
			do j = 1, NREC(i) {
			    stat = read (ret_fd, Meml[dat + offset], LREC(i))
			    len = stat
			    if (len != LREC(i)) {
				call eprintf ("%s:  wanted %d chars, got %d chars\n")
				    call pargstr (ret_fname)
				    call pargl (LREC(i))
				    call pargi (len)
			    }
			    offset = offset + len / SZ_LONG
			}
		    }
		    call achtbl (Meml[dat], Meml[dat], nchars * SZB_CHAR)

		    call dg_uint_to_long (Meml[dat], REV_OFFSET, REV_N(ret))
		    if (REV_N(ret) <= 0)
			in_range = true
		    else {
			call dg_uint_to_long (Meml[dat], DISK_OFFSET, DISK_N(ret))
			call dg_uint_to_long (Meml[dat], FILE_OFFSET, FILE_N(ret))
			in_range = is_in_range (DRANGE(cp), int (DISK_N(ret))) &&
				    is_in_range (PRANGE(cp), int (FILE_N(ret)))
		    }

		    if (in_range) {
			# Convert the header and data
			call ret_convert_header (dat, dret, ret)
			call dg_nuint_to_long (Meml[dat], Meml[dat],
						DATLEN / NBYTES_PER_PIXEL)

			if (BEAM(ret) == 2) {
			    noff = 1
			    beam_base = 0
			    # half of the data is in each beam
			    NDATA(ret) = (DATLEN / NBYTES_PER_PIXEL) / 2
			} else {
			    noff = 0
			    beam_base = BEAM(ret)
			    # convert from bytes to pixels
			    NDATA(ret) = DATLEN / NBYTES_PER_PIXEL
			}

			do i = 0, noff {
			    BEAM(ret) = beam_base + i
			    data_off = i * NDATA(ret)

			    if (MAKE_IMAGE(cp) == YES)
				call strcpy (" -> ", str, 10)
			    else
				call strcpy (":  ", str, 10)
			    call printf ("%s%s")
				call pargstr (ret_fname)
				call pargstr (str)

			    if (MAKE_IMAGE(cp) == YES) {
				# Build the output filename
				call strcpy (iraf_root, iraf_fname, SZ_FNAME)
				if (NFILES(cp) > 1 || noff > 0) {
				    call sprintf (iraf_fname[strlen (iraf_fname) + 1],
					    SZ_FNAME, "%04d")
					call pargl (START_NUMBER(cp) +
						    SEQ_NUMBER(cp))
				}
				call printf ("%s")
				    call pargstr (iraf_fname)
				if (LONG_HEADER(cp) == NO)
				    call printf (":  ")
			    }

			    call ret_print_header (dret, ret, LONG_HEADER(cp))

			    if (MAKE_IMAGE(cp) == YES) {
				# Check if image exists and should be overwritten.
				if (imaccess (iraf_fname, 0) == YES) {
				    if (OVERWRITE(cp) == YES)
					call imdelete (iraf_fname)
				    else {
					call sprintf (str, 80,
					     "image name '%s' already exists")
					    call pargstr (iraf_fname)
					call error (1, str)
					goto exit_
				    }
				}
			    } else
				next
			
			    # Map new IRAF image structure and set up header
			    iferr (im = immap (iraf_fname, NEW_IMAGE, LEN_USER_AREA)) {
				call sprintf (str, 80, "Cannot open image '%s'")
				    call pargstr (iraf_fname)
				call error (1, str)
				goto exit_
			    }
			    IM_PIXTYPE(im) = DATA_TYPE(cp)
			    IM_LEN(im, 1) = NDATA(ret)
			    call strcpy (OBJECT(ret), IM_TITLE(im), SZ_IMTITLE)

			    iferr (pt = impl1l(im)) {
				call imunmap (im)
				call imdelete (iraf_fname)
				call sprintf (str, 80,
					      "Cannot write to image '%s'")
				    call pargstr (iraf_fname)
				call error (1, str)
				goto exit_
			    }
			    call amovl (Meml[dat + data_off], Meml[pt],
					IM_LEN(im, 1))

			    call ret_store_keywords (dret, ret, im)
			    call imunmap (im)

			    SEQ_NUMBER(cp) = SEQ_NUMBER(cp) + 1
			}
		    } else {
			stat = ERR
		    }
		}
	    } else {
		call eprintf ("%s:  unknown record type = %d\n")
		    call pargstr (ret_fname)
		    call pargl (type)
		stat = ERR
	    }
	}

exit_ 	call flush (STDOUT)
	
	# Close files and clean up
	call close (ret_fd)
	call sfree (sp)

	return (stat)
end
