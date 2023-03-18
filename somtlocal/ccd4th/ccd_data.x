include <error.h>
include <imhdr.h>
include <mach.h>
include "ccd4th.h"

# CCD_DATA.X - Routines to read CCD FORTH data records and write IRAF images.

# Steward Observatory CCD FORTH tape format:
#
#     A picture from the data-taking computer disk is written to tape as
# logical tracks, with N_BLOCKS_PER_TRACK tape records making up that track.
# Each track contains as many picture lines as will fit in their entirety:
# a line is not split between tracks.	The number of lines per track is
# LPT = NPIX_PER_TRACK / NPIX1.  The last track contains 1 to LPT lines.
# Everything in a track beyond the end of the lines is garbage.
#
#     Before the data is written to tape, a header track is written.
# Only the first tape record of the header track contains useful
# information.	Thus, N_HEADER_PAD_BLOCKS = N_BLOCKS_PER_TRACK - 1
# tape records follow the header record before the data records begin.
#
#     Each tape record contains 512 16-bit words of information.
# A 513-th word identifies the type of record:	a non-zero value
# identifies a header record (beginning of a header track), and a
# zero value is non-header record.

define BUF_POS	    buf[NBYTES_PER_PIXEL * NPIX_PER_RECORD * ($1) + 1]


# CCD_RW_PICTURE - read ccd picture and create IRAF image.

procedure ccd_rw_picture (fd, ccd, out_fname, data_type)

int	fd			# file descriptor
pointer ccd			# pointer to program data structure
char	out_fname[ARB]		# name of output file
long	data_type		# data type of output image

int	i, lpt, nlines, curline, nd
int	ltrack			# number of lines in last track
int	ntracks 		# number of tracks in picture
pointer sp, pixels, im, pt

pointer immap(), imps2l()

define	exit_	91

begin
	# Allocate space on stack for track buffer to be stored with one byte
	# per element.
	call smark (sp)
	call salloc (pixels, (NPIX_PER_TRACK+1) * NBYTES_PER_PIXEL, TY_LONG)
					# the extra 1 is for last 513-th word

	# Skip the blocks after the header in the first track.
	iferr (call ccd_read_records (fd, Meml[pixels], N_HEADER_PAD_BLOCKS)) {
	    call erract (EA_WARN)
	    goto exit_
	}

	lpt = NPIX_PER_TRACK / NPIX(ccd, 1)
	ntracks = NPIX(ccd, 2) / lpt
	if (ntracks * lpt < NPIX(ccd, 2)) {
	    ltrack = NPIX(ccd, 2) - ntracks * lpt
	    ntracks = ntracks + 1
	} else
	    ltrack = lpt

	# Map new IRAF image structure and set up header
	iferr (im = immap (out_fname, NEW_IMAGE, LEN_USER_AREA)) {
	    call eprintf ("Cannot open image '%s'\n")
		call pargstr (out_fname)
	    call erract (EA_WARN)
	    goto exit_
	}
	IM_PIXTYPE(im) = data_type
	if (N_DIM(ccd) >= 1 && N_DIM(ccd) <= 3)
	    nd = N_DIM(ccd)
	else
	    nd = 2
	do i = 1, nd
	    IM_LEN(im, i) = NPIX(ccd, i)
	call strcpy (NAME(ccd), IM_TITLE(im), SZ_IMTITLE)

	# Process the picture, track by track
	curline = 1
	do i = 1, ntracks {
	    iferr (call ccd_read_records (fd, Meml[pixels], N_BLOCKS_PER_TRACK)) {
		call eprintf ("Cannot read FORTH input file\n")
		call imunmap (im)
		call imdelete (out_fname)
		call erract (EA_WARN)
		goto exit_
	    }
	    call dg_nuint_to_long (Meml[pixels], Meml[pixels],
		 NPIX_PER_TRACK)
	    if (i == ntracks)
		nlines = ltrack
	    else
		nlines = lpt
	    iferr (pt = imps2l(im, 1, NPIX(ccd,1), curline, curline+nlines-1)) {
		call eprintf ("Cannot write to image '%s'\n")
		    call pargstr (out_fname)
		call imunmap (im)
		call imdelete (out_fname)
		call erract (EA_WARN)
		goto exit_
	    }
	    call amovl (Meml[pixels], Meml[pt], nlines * NPIX(ccd, 1))
	    curline = curline + nlines
	}

	call ccd_store_keywords (ccd, im)
	call imunmap (im)
exit_ 	call sfree (sp)
end


# CCD_READ_RECORDS - Read CCD FORTH records from tape file.
# Read each of 'n' data records.  Convert each record to an array of bytes,
# and check the last (513-th) word.  Note any header records which are read
# (should not be any).	Overwrite the last word with the next record, so that
# in the end, 'buf' will contain 'n' records of data (as an array of byte
# values) without the intervening 513-th words.

procedure ccd_read_records (fd, buf, n)

int	fd			# file descriptor
long	buf[ARB]		# buffer to fill with 'n' records of data
int	n			# number of records to read

int	i
long	j

int	read()

errchk	read

begin
	do i = 0, n - 1 {
	    if (read (fd, BUF_POS(i), SZB_FORTH_RECORD/SZB_CHAR) == EOF) {
		call error (1, "Unexpected EOF")
		return
	    } else {
		call achtbl (BUF_POS(i), BUF_POS(i), SZB_FORTH_RECORD)
		call dg_uint_to_long (BUF_POS(i), HEADER_NO_OFFSET, j)
		if (j != 0) {
		    call eprintf ("Unexpected header = %d encountered\n")
			call pargl (j)
		}
	    }
	}
end
