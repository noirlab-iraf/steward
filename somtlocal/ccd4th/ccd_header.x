include <imhdr.h>
include <imio.h>
include <time.h>
include "ccd4th.h"

# CCD_HEADER.X - Support routines for decoding and printing CCD FORTH headers.

define SZ_MONTH     3
define MAX_STR	    100
define MST_TO_UT    (7 * 3600)	    # seconds ( = 7 hours to add)
define MS_PER_HOUR  3600000.D0	    # milliseconds per hour
define LMS_PER_HOUR 3600000	    # long form of MS_PER_HOUR


# CCD_CONVERT_HEADER - Convert header information to the program data structure.

procedure ccd_convert_header (c4b, ccd)

long	c4b[ARB]	    # buffer of unpacked CCD record - one byte/int
pointer ccd		    # pointer to program data structure

int	i

begin
	# Convert all unsigned 2 byte values
	call dg_uint_to_long (c4b, N_DATA_BLOCKS_OFFSET, N_DATA_BLOCKS(ccd))

	# call dg_uint_to_long (c4b, PICTURE_N_OFFSET, PICTURE_N(ccd)) done by caller
	call dg_uint_to_long (c4b, BLOCK_N_OFFSET, BLOCK_N(ccd))
	call dg_uint_to_long (c4b, FORTH_DATA_TYPE_OFFSET, FORTH_DATA_TYPE(ccd))
	call dg_uint_to_long (c4b, NPIX1_OFFSET, NPIX(ccd, 1))
	call dg_uint_to_long (c4b, NPIX2_OFFSET, NPIX(ccd, 2))
	call dg_uint_to_long (c4b, NPIX3_OFFSET, NPIX(ccd, 3))
	call dg_uint_to_long (c4b, N_DIM_OFFSET, N_DIM(ccd))

	if (N_DIM(ccd) >=0 && N_DIM(ccd) <= 2)
	    do i = N_DIM(ccd) + 1, 3
	        NPIX(ccd, i) = 1

	call dg_uint_to_long (c4b, YEAR_OFFSET, YEAR(ccd))
	if (abs (YEAR(ccd)) < 100)
	    YEAR(ccd) = abs (YEAR(ccd)) + 1900
	call dg_uint_to_long (c4b, MONTH_DAY_OFFSET, DAY(ccd))
	MONTH(ccd) = abs (DAY(ccd)) / 100
	DAY(ccd) = mod (abs (DAY(ccd)), 100)
	call dg_uint_to_long (c4b, SHUTTER_OFFSET, SHUTTER(ccd))
	call dg_uint_to_long (c4b, PHASE_OFFSET, PHASE(ccd))
	call dg_uint_to_long (c4b, AIRMASS_OFFSET, AIRMASS(ccd))
	call dg_uint_to_long (c4b, TAPE_NO_OFFSET, TAPE_NO(ccd))
	call dg_uint_to_long (c4b, PREFLASH_OFFSET, PREFLASH(ccd))
	if (PREFLASH(ccd) > 4095)
	    PREFLASH(ccd) = 0

	# convert all signed 2 byte values
	call dg_sint_to_long (c4b, CTEMP_OFFSET, CTEMP(ccd))
	call dg_sint_to_long (c4b, DTEMP_OFFSET, DTEMP(ccd))

	# convert all unsigned 4 byte values
	call dg_ulong_to_long (c4b, N_WORDS_OFFSET, N_WORDS(ccd))
	call dg_ulong_to_long (c4b, RA_OFFSET, RA(ccd))
	call dg_ulong_to_long (c4b, START_OFFSET, START(ccd))
	call dg_ulong_to_long (c4b, STOP_OFFSET, STOP(ccd))
	call dg_ulong_to_long (c4b, EXP_OFFSET, EXP(ccd))
	call dg_ulong_to_long (c4b, SID_OFFSET, SID(ccd))

	# convert all signed 4 byte values
	call dg_slong_to_long (c4b, DEC_OFFSET, DEC(ccd))
	call dg_slong_to_long (c4b, HA_OFFSET, HA(ccd))

	# convert all text fields
	call dg_char_to_char (c4b, NAME_OFFSET, SZ_TEXT_FIELD, NAME(ccd))
	call dg_char_to_char (c4b, CHIP_NAME_OFFSET, SZ_TEXT_FIELD,
					CHIP_NAME(ccd))
	call dg_char_to_char (c4b, MODE_OFFSET, SZ_TEXT_FIELD, MODE(ccd))
	call dg_char_to_char (c4b, FILTER_OFFSET, SZ_TEXT_FIELD, FILTER(ccd))
	call dg_char_to_char (c4b, DISPERSER_OFFSET, SZ_TEXT_FIELD,
					DISPERSER(ccd))
	call dg_char_to_char (c4b, TILT_OFFSET, SZ_TEXT_FIELD, TILT(ccd))
	call dg_char_to_char (c4b, APERTURE_OFFSET, SZ_TEXT_FIELD,
					APERTURE(ccd))
	do i = 1, 5
	    call dg_char_to_char (c4b, COMMENTS_OFFSET(i), SZ_COMMENT_FIELD,
					COMMENTS(ccd, i))
end


# CCD_PRINT_HEADER - Print the CCD header in either long or short mode.

procedure ccd_print_header (ccd, long_header)

pointer ccd			# pointer to program data structure
long	long_header		# print header in long format (YES/NO)?

int	i
char	mname[SZ_MONTH]
int	strlen()
string	month "JanFebMarAprMayJunJulAugSepOctNovDec"

begin
	if (long_header == YES) {
	    call printf ("PICTURE = %d, label = \"%s\",\n")
		call pargl (PICTURE_N(ccd))
		call pargstr (NAME(ccd))
	    call printf ("Ndim = %d,")
		call pargl (N_DIM(ccd))
	    if (N_DIM(ccd) >= 1) {
		call printf ("   Ncols = %d,")
		    call pargl (NPIX(ccd, 1))
	    }
	    if (N_DIM(ccd) >= 2) {
		call printf ("   Nlines = %d,")
		    call pargl (NPIX(ccd, 2))
	    }
	    if (N_DIM(ccd) >= 3) {
		call printf ("   Nframes = %d,")
		    call pargl (NPIX(ccd, 3))
	    }
	    call printf ("\nITM = %d sec, START = %h, STOP = %h (MST)\n")
		call pargl ((EXP(ccd)+500)/1000)   # round off to nearest second
		call pargd (double (START(ccd))/MS_PER_HOUR)
		call pargd (double (STOP(ccd))/MS_PER_HOUR)
	    if (MONTH(ccd) >= 1 && MONTH(ccd) <= 12)
	        call strcpy (month[(MONTH(ccd) - 1) * SZ_MONTH + 1], mname,
			    SZ_MONTH)
	    else {
		call printf ("bad month = %d\n")
		    call pargl (MONTH(ccd))
		call strcpy ("???", mname, SZ_MONTH)
	    }
	    call printf ("date = %d %s %d, ST = %h, ")
		call pargl (DAY(ccd))
		call pargstr (mname)
		call pargl (YEAR(ccd))
		call pargd (double (SID(ccd))/MS_PER_HOUR)

	    # Only the else part of the following 'if' is needed when %h for
	    # negative values is working correctly.
	    if (HA(ccd) < 0) {
	        call printf ("HA = -%h\n")
		    call pargd (double (-HA(ccd))/MS_PER_HOUR)
	    } else {
	        call printf ("HA = %h\n")
		    call pargd (double (HA(ccd))/MS_PER_HOUR)
	    }

	    call printf ("RA = %h, ")
		call pargd (double (RA(ccd))/MS_PER_HOUR)

	    # Only the else part of the following 'if' is needed when %h for
	    # negative values is working correctly.
	    if (DEC(ccd) < 0) {
	        call printf ("DEC = -%h\n")
		    call pargd (double (-DEC(ccd))/MS_PER_HOUR)
	    } else {
	        call printf ("DEC = %h\n")
		    call pargd (double (DEC(ccd))/MS_PER_HOUR)
	    }

	    if (SHUTTER(ccd) == 1)
		call printf ("shutter = OPEN,")
	    else
		call printf ("shutter = CLOSED,")
	    call printf (" preflash = %d cycles, phase = %d, airmass = %0.3f\n")
		call pargl (PREFLASH(ccd))
		call pargl (PHASE(ccd))
		call pargr (real (AIRMASS(ccd))/1000.)
	    call printf ("Ctemp = %d, Dtemp = %d, tape # = %d\n")
		call pargl (CTEMP(ccd))
		call pargl (DTEMP(ccd))
		call pargl (TAPE_NO(ccd))
	    call printf ("chip = \"%s\",   mode = \"%s\",\n")
		call pargstr (CHIP_NAME(ccd))
		call pargstr (MODE(ccd))
	    call printf ("filter = \"%s\",   disperser = \"%s\",\n")
		call pargstr (FILTER(ccd))
		call pargstr (DISPERSER(ccd))
	    call printf ("tilt = \"%s\",   aperture = \"%s\",\n")
		call pargstr (TILT(ccd))
		call pargstr (APERTURE(ccd))
	    call printf ("comments:\n")
	    do i = 1, 5 {
		if (strlen (COMMENTS(ccd, i)) > 0) {
		    call printf ("   %s\n")
			call pargstr (COMMENTS(ccd, i))
		}
	    }
	    call printf ("\n")
	} else {
	    call printf ("PICTURE = %d, label = \"%s\", ITM = %d sec\n")
		call pargl (PICTURE_N(ccd))
		call pargstr (NAME(ccd))
		call pargl ((EXP(ccd)+500)/1000)   # round off to nearest second
	}
	call flush (STDOUT)
end


# CCD_STORE_KEYWORDS - Store CCD specific keywords in the IRAF image header.

procedure ccd_store_keywords (ccd, im)

pointer ccd	    # pointer to program data structure
pointer im	    # pointer to image

char	str[MAX_STR]
int	fd, tm[LEN_TMSTRUCT], npr, i, length_uarea
long	uttime
real	value
double	dvalue
int	stropen(), strlen()
long	sectime()

begin
	# Open image user area as a string

	length_uarea = (LEN_IMDES + IM_LENHDRMEM(im) - IMU) * SZ_STRUCT - 1
	fd = stropen (Memc[IM_USERAREA(im)], length_uarea, WRITE_ONLY)

	# FITS keywords are formatted and appended to the image user area with
	# the addcard procedures.

	call addcard_st (fd, "OBJECT", NAME(ccd), "object name",
			    strlen (NAME(ccd)))
	call addcard_i (fd, "CCDPICNO", int (PICTURE_N(ccd)),
			    "original ccd picture number")
	value = real (EXP(ccd)) / 1000.
	if (value <= 0.)
	    npr = 3
	else
	    npr = max (min (int (log10 (value)) + 4, 7), 3)
	call addcard_r (fd, "EXPTIME", value,
			    "actual integration time (seconds)", npr)
	value = real (STOP(ccd) - START(ccd)) / 1000.
	if (value <= 0.)
	    npr = 3
	else
	    npr = max (min (int (log10 (value)) + 4, 7), 3)
	call addcard_r (fd, "DARKTIME", value, "total elapsed time (seconds)",
			    npr)
	if (SHUTTER(ccd) == 1)
	    call strcpy ("OBJECT", str, MAX_STR)
	else
	    call strcpy ("DARK", str, MAX_STR)
	call addcard_st (fd, "IMAGETYP", str, "object, dark, bias, etc.",
			    strlen (str))

	# Convert MST to UT
	TM_YEAR(tm) = YEAR(ccd)
	TM_MONTH(tm) = MONTH(ccd)
	TM_MDAY(tm) = DAY(ccd)
	TM_HOUR(tm) = START(ccd) / LMS_PER_HOUR
	TM_MIN(tm) = 0
	TM_SEC(tm) = 0
	uttime = sectime (tm) + MST_TO_UT
	call brktime (uttime, tm)

	call sprintf (str, MAX_STR, "%02d/%02d/%02d")
	    call pargi (TM_MDAY(tm))
	    call pargi (TM_MONTH(tm))
	    call pargi (mod (TM_YEAR(tm), 100))
	call addcard_st (fd, "DATE-OBS", str, "date (dd/mm/yy) of observation",
			    strlen (str))
	dvalue = double (RA(ccd)) / MS_PER_HOUR
	call addcard_time (fd, "RA", dvalue, "right ascension (telescope)")
	dvalue = double (DEC(ccd)) / MS_PER_HOUR
	call addcard_time (fd, "DEC", dvalue, "declination (telescope)")
	dvalue = double (START(ccd) + (TM_HOUR(tm) - START(ccd) /
			    LMS_PER_HOUR) * LMS_PER_HOUR) / MS_PER_HOUR
	call addcard_time (fd, "UT", dvalue, "universal time")
	dvalue = double (SID(ccd)) / MS_PER_HOUR
	call addcard_time (fd, "ST", dvalue, "sidereal time")
	dvalue = double (HA(ccd)) / MS_PER_HOUR
	call addcard_time (fd, "HA", dvalue, "hour angle")
	if (AIRMASS(ccd) != 0) {
	    value = real (AIRMASS(ccd)) / 1000.
	    call addcard_r (fd, "AIRMASS", value, "airmass", 4)
	}
	if (strlen (CHIP_NAME(ccd)) > 0) {
	    call addcard_st (fd, "DETECTOR", CHIP_NAME(ccd), "detector",
				strlen (CHIP_NAME(ccd)))
	}
	if (PREFLASH(ccd) != 0) {
	    value = real (PREFLASH(ccd)) * SECS_PER_CYCLE
	    call addcard_r (fd, "PREFLASH", value, "preflash time (seconds)", 4)
	}
	call addcard_i (fd, "CAMTEMP", int (CTEMP(ccd)),
			    "camera temperature, deg C")
	call addcard_i (fd, "DEWTEMP", int (DTEMP(ccd)),
			    "dewar temperature, deg C")
	if (strlen (FILTER(ccd)) > 0)
	    call addcard_st (fd, "FILTERS", FILTER(ccd), "filters",
				strlen (FILTER(ccd)))
	if (strlen (TILT(ccd)) > 0)
	    call addcard_st (fd, "TILT", TILT(ccd), "tilt", strlen (TILT(ccd)))
	if (strlen (MODE(ccd)) > 0)
	    call addcard_st (fd, "MODE", MODE(ccd), "mode", strlen (MODE(ccd)))
	call addcard_i (fd, "PHASE", int (PHASE(ccd)), "phase")
	if (strlen (DISPERSER(ccd)) > 0)
	    call addcard_st (fd, "DISPERSE", DISPERSER(ccd), "disperser",
				strlen (DISPERSER(ccd)))
	if (strlen (APERTURE(ccd)) > 0)
	    call addcard_st (fd, "APERTURE", APERTURE(ccd), "aperture",
				strlen (APERTURE(ccd)))
	do i = 1, 5
	    if (strlen (COMMENTS(ccd, i)) > 0)
		call addcard_com (fd, "COMMENT", COMMENTS(ccd, i))

	call strclose (fd)
end
