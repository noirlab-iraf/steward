include <imhdr.h>
include <imio.h>
include <time.h>
include "retmmt.h"

# RET_HEADER.X - Support routines for decoding and printing Reticon headers.

define SZ_MONTH		3
define MAX_STR	    100
define MST_TO_UT    (7 * 3600)	        # seconds ( = 7 hours to add)
define MSEC_PER_MIN	60000		# milliseconds per minute
define MSEC_PER_TENTHS    100		# milliseconds per tenths of seconds
define MS_PER_HOUR	3600000.D0	# milliseconds per hour
define LMS_PER_HOUR     3600000	        # long form of MS_PER_HOUR

define CH		Memc[buf+($1)-1]
define BUF		Memc[buf+($1)-1]


# RET_CONVERT_HEADER - Convert header information to the program data structure.

procedure ret_convert_header (dat, dret, ret)

pointer	dat		# pointer to buffer of unpacked Reticon data -
			#   one byte/long
pointer	dret		# pointer to program data structure
pointer	ret		# pointer to program data structure

int	i
long	ts, min, count

begin
	# call dg_uint_to_long (Meml[dat], REV_OFFSET, REV_N(ret))   done by caller

	call dg_uint_to_long (Meml[dat], EXP_OFFSET, EXP_TIME(ret))
	call dg_uint_to_long (Meml[dat], MONTH_OFFSET, MONTH(ret))
	call dg_uint_to_long (Meml[dat], DAY_OFFSET, DAY(ret))
	call dg_uint_to_long (Meml[dat], YEAR_OFFSET, YEAR(ret))
	if (abs (YEAR(ret)) < 100)
	    YEAR(ret) = abs (YEAR(ret)) + 1900

	call dg_uint_to_long (Meml[dat], LSTM_OFFSET, min)
	call dg_uint_to_long (Meml[dat], LSTS_OFFSET, ts)
	LOCAL_T(ret) = min * MSEC_PER_MIN + ts * MSEC_PER_TENTHS

	call dg_uint_to_long (Meml[dat], STM_OFFSET, min)
	call dg_uint_to_long (Meml[dat], STS_OFFSET, ts)
	SID_T(ret) = min * MSEC_PER_MIN + ts * MSEC_PER_TENTHS

	call dg_dfloat_to_double (Meml[dat], JDN_OFFSET, JDN(dret))

	if (REV_N(ret) >= 1) {

	    # call dg_uint_to_long (Meml[dat], DISK_OFFSET, DISK_N(ret)) done by caller
	    # call dg_uint_to_long (Meml[dat], FILE_OFFSET, FILE_N(ret)) done by caller

	    # Replace the FILE_ID from the id record by the name in this
	    # fixed point parameter record.
	    # The first character of FILE_ID is the length of the string.

	    call dg_ubyte_to_long (Meml[dat], FILE_ID_OFFSET, count)
	    if (count > SZ_TEXT_FIELD)
		count = SZ_TEXT_FIELD
	    call dg_char_to_char (Meml[dat], FILE_ID_OFFSET + 1,
		     int (count), FILE_ID(ret))

	    call dg_uint_to_long (Meml[dat], SITE_OFFSET, SITE(ret))
	    switch (SITE(ret)) {
	    case 0:
		call strcpy ("MMT", SITE_NAME(ret), SZ_LABEL)
	    case 1:
		call strcpy ("Ridge", SITE_NAME(ret), SZ_LABEL)
	    case 2:
		call strcpy ("Agassiz", SITE_NAME(ret), SZ_LABEL)
	    default:
		call strcpy ("?unknown?", SITE_NAME(ret), SZ_LABEL)
	    }
	}

	if (REV_N(ret) >= 3) {
	    call dg_uint_to_long (Meml[dat], BEAM_OFFSET, BEAM(ret))
	}

	do i = 1, 16 {
	    call dg_char_to_char (Meml[dat], COMMENTS_OFFSET(i),
		     SZ_COMMENT_FIELD, COMMENTS(ret, i))
	}

	call get_object (ret)
	if (REV_N(ret) >= 1) {
	    call sprintf (LABEL(ret), SZ_LABEL, "%d %d %s")
		call pargl (DISK_N(ret))
		call pargl (FILE_N(ret))
		call pargstr (OBJECT(ret))
	}
	call get_ra_dec (dret, ret)
end


# RET_PRINT_HEADER - Print the Reticon header in either long or short mode.

procedure ret_print_header (dret, ret, long_header)

pointer	dret		# pointer to program data structure
pointer	ret		# pointer to program data structure
long	long_header	# print header in long format (YES/NO)?

int	i
long	len
char 	mname[SZ_MONTH]

int	strlen()

string	month "JanFebMarAprMayJunJulAugSepOctNovDec"

begin
	if (long_header == YES) {
	    call printf ("\nlabel = \"%s\"\n")
		call pargstr (LABEL(ret))
	    if (REV_N(ret) >= 1) {
		call printf ("disk = %d,  file = %d,\n")
		    call pargl (DISK_N(ret))
		    call pargl (FILE_N(ret))
	    }
	    call printf ("Ndim = 1,  Nch = %d,\n")
		call pargl (NDATA(ret))
	    call printf ("ITM = %d sec,  local standard time = %h (MST)\n")
		call pargl (EXP_TIME(ret))
		call pargd (double (LOCAL_T(ret)) / MS_PER_HOUR)
	    
	    if (MONTH(ret) >= 1 && MONTH(ret) <= 12)
		call strcpy (month[(MONTH(ret) - 1) * SZ_MONTH + 1],
			mname, SZ_MONTH)
	    else {
		call printf ("bad month = %d\n")
		    call pargl (MONTH(ret))
		call strcpy ("???", mname, SZ_MONTH)
	    }

	    call printf ("date = %d %s %d,  ST = %h\n")
		call pargl (DAY(ret))
		call pargstr (mname)
		call pargl (YEAR(ret))
		call pargd (double (SID_T(ret)) / MS_PER_HOUR)
	    call printf ("Greenwich JDN = %.6f\n")
		call pargd (JDN(dret))
	    
	    switch (RA_DEC(ret)) {
	    case HAVE_RA_DEC:
		call printf ("RA = %h,  ")
		    call pargd (double (RA(ret)) / MS_PER_HOUR)
		
		# Only the else part of the following 'if' is needed when %h
		# for negative values is working correctly.
		if (DEC(ret) < 0) {
		    call printf ("DEC = -%h")
			call pargd (double (-DEC(ret)) / MS_PER_HOUR)
		} else {
		    call printf ("DEC = %h")
			call pargd (double (DEC(ret)) / MS_PER_HOUR)
		}
		if (EPOCH(dret) > 0.D0) {
		    call printf ("  Epoch = %.1f\n")
			call pargd (EPOCH(dret))
		} else {
		    call printf ("\n")
		}
	    case STOW_RA_DEC:
		call printf ("RA = STOW,  DEC = STOW\n")
	    }

	    if (REV_N(ret) >= 1) {
		call printf ("Site = %s,")
		    call pargstr (SITE_NAME(ret))
	    }
	    if (REV_N(ret) >= 3) {
		call printf ("  Beam = %d,")
		    call pargl (BEAM(ret))
	    }
	    if (REV_N(ret) >= 1)
		call printf ("\n")
	    
	    len = 0
	    do i = 1, 16
		len = len + strlen (COMMENTS(ret, i))
	    if (len > 0) {
		call printf ("comments:\n")
		do i = 1, 16 {
		    if (strlen (COMMENTS(ret, i)) > 0) {
			call printf ("    %s\n")
			    call pargstr (COMMENTS(ret, i))
		    }
		}
	    }
	} else {
	    call printf ("\"%s\"  ITM = %d sec")
		call pargstr (LABEL(ret))
		call pargl (EXP_TIME(ret))
	}
	call printf ("\n")
end


# RET_STORE_KEYWORDS - Store Reticon specific keywords in the IRAF image header.

procedure ret_store_keywords (dret, ret, im)

pointer dret	    # pointer to program data structure
pointer ret	    # pointer to program data structure
pointer im	    # pointer to image

char	str[MAX_STR]
int	fd, tm[LEN_TMSTRUCT], i, length_uarea, npr
long	uttime
double	dvalue

int	stropen(), strlen()
long	sectime()

begin
	# Open image user area as a string

	length_uarea = (LEN_IMDES + IM_LENHDRMEM(im) - IMU) * SZ_STRUCT - 1
	fd = stropen (Memc[IM_USERAREA(im)], length_uarea, WRITE_ONLY)

	# FITS keywords are formatted and appended to the image user area with
	# the addcard procedures.

	if (REV_N(ret) >= 1)
	    call addcard_st (fd, "OBSERVAT", SITE_NAME(ret), "origin of data",
				 strlen (SITE_NAME(ret)))
	call addcard_st (fd, "OBJECT", OBJECT(ret), "object name",
			     strlen (OBJECT(ret)))
	if (REV_N(ret) >= 1) {
	    call addcard_i (fd, "RETDISKN", int (DISK_N(ret)),
				"original Reticon disk number")
	    call addcard_i (fd, "RETFILEN", int (FILE_N(ret)),
				"original Reticon file number")
	}
	call addcard_r (fd, "EXPTIME", real (EXP_TIME(ret)),
			    "actual integration time (seconds)", 0)

	# Convert MST to UT
	TM_YEAR(tm) = YEAR(ret)
	TM_MONTH(tm) = MONTH(ret)
	TM_MDAY(tm) = DAY(ret)
	TM_HOUR(tm) = LOCAL_T(ret) / LMS_PER_HOUR
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
	if (JDN(dret) <= 0.D0)
	    npr = 6
	else
	    npr = max (min (int (log10 (JDN(dret))) + 7, 16), 6)
	call addcard_d (fd, "JDN", JDN(dret), "greenwich julian day number", npr)

	if (RA_DEC(ret) == HAVE_RA_DEC) {
	    dvalue = double (RA(ret)) / MS_PER_HOUR
	    call addcard_time (fd, "RA", dvalue, "right ascension (telescope)")
	    dvalue = double (DEC(ret)) / MS_PER_HOUR
	    call addcard_time (fd, "DEC", dvalue, "declination (telescope)")
	    if (EPOCH(dret) > 0.D0) {
		npr = max (min (int (log10 (EPOCH(dret))) + 2, 16), 1)
		call addcard_r (fd, "EPOCH", real (EPOCH(dret)),
				    "epoch of ra and dec", npr)
	    }
	}

	dvalue = double (LOCAL_T(ret) + (TM_HOUR(tm) - LOCAL_T(ret) /
			    LMS_PER_HOUR) * LMS_PER_HOUR) / MS_PER_HOUR
	call addcard_time (fd, "UT", dvalue, "universal time")
	dvalue = double (SID_T(ret)) / MS_PER_HOUR
	call addcard_time (fd, "ST", dvalue, "sidereal time")

	if (REV_N(ret) >= 3)
	    call addcard_i (fd, "BEAM-NUM", int (BEAM(ret)), "beam number")

	do i = 1, 16
	    if (strlen (COMMENTS(ret, i)) > 0)
		call addcard_com (fd, "COMMENT", COMMENTS(ret, i))

	call strclose (fd)
end


# GET_OBJECT - Get the object name from the comments.

procedure get_object (ret)

pointer ret		# pointer to program data structure

int	i, after, beg, endd, len, pos

pointer sp, buf

int	strlen(), strmatch()

begin
	call smark (sp)
	call salloc (buf, SZ_COMMENT_FIELD+1, TY_CHAR)

	call strcpy (FILE_ID(ret), OBJECT(ret), SZ_LABEL)

	do i = 1, 16 {
	    after = strmatch (COMMENTS(ret, i), "OBJECT:")
	    if (after > 0) {
		call strcpy (COMMENTS(ret, i), BUF(1), SZ_COMMENT_FIELD)
		len = strlen (BUF(1))
		beg = len + 1
		do pos = after, len {
		    if (CH(pos) != ' ') {
			beg = pos
			break
		    }
		}
		endd = beg - 1
		do pos = len, beg, -1 {
		    if (CH(pos) != ' ') {
			endd = pos
			break
		    }
		}
		CH(endd+1) = EOS
		if (strlen (BUF(beg)) > 0) {
		    call strcpy (BUF(beg), OBJECT(ret), SZ_LABEL)
		}
	    }
	}

	call sfree (sp)
end


# GET_RA_DEC - Get the RA, DEC, and EPOCH from the comments.

procedure get_ra_dec (dret, ret)

pointer	dret		# pointer to program data structure
pointer	ret		# pointer to program data structure

int	i, afterr, afterd, pos, sign, n
double	ms, limit, angle[3]
pointer	sp, buf

int	strmatch(), sscan(), nscan()

begin
	call smark (sp)
	call salloc (buf, SZ_COMMENT_FIELD+1, TY_CHAR)

	RA_DEC(ret) = NO_RA_DEC
	RA(ret) = 0
	DEC(ret) = 0
	EPOCH(dret) = -1.D0
	
	do i = 1, 16 {
	    afterr = strmatch (COMMENTS(ret, i), "R.A.")
	    afterd = strmatch (COMMENTS(ret, i), "Dec")
	    if ((afterr + afterd) > 0) {
		if (strmatch (COMMENTS(ret, i), "STOW") > 0) {
		    RA_DEC(ret) = STOW_RA_DEC
		} else {
		    call strcpy (COMMENTS(ret, i), BUF(1), SZ_COMMENT_FIELD)
		    if (afterr > 0)
			pos = afterr
		    else
			pos = afterd
		    sign = strmatch (BUF(1), "-")
		    if (sign > 0) {
			pos = sign
			sign = -1
		    } else
			sign = 1
		    # components may be separated by colons (:)
		    if (strmatch (BUF(1), ":") > 0) {
			n = 1
			while (BUF(n) != EOS) {
			    if (BUF(n) == ':') {
				BUF(n) = ' '
			    }
			    n = n + 1
			}
		    }
		    if (sscan (BUF(pos)) != EOF) {
			call gargd (angle[1])
			call gargd (angle[2])
			call gargd (angle[3])
			n = nscan()
			if (n > 0) {
			    if (n <= 2)
				angle[3] = 0.D0
			    if (n <= 1)
				angle[2] = 0.D0
			    # ms is milli-seconds:  time or arc
			    ms = 1000.D0*(60.D0*(60.D0*angle[1]+angle[2])+angle[3])
			    # angle may have been written without spaces, in 
			    # which case, "ms" is way too big
			    # check against an appropriate limit
	    		    if (afterr > 0)
				limit = 24.D0		# 24 hours
			    else
				limit = 90.D0		# 90 degrees
			    if (ms > limit*3600.D0*1000.D0) {
				ms = angle[1]
				n = ms / 10000.D0
				angle[1] = n
				ms = ms - 10000.D0*angle[1]
				n = ms / 100.D0
				angle[2] = n
				ms = ms - 100.D0*angle[2]
				angle[3] = ms
			        ms = 1000.D0*(60.D0*(60.D0*angle[1]+angle[2])+angle[3])
			    }
			    if (sign == -1)
				ms = -ms
			    if (afterr > 0) {
				RA(ret) = long (ms + 0.5D0)
			    } else {
				DEC(ret) = long (ms + 0.5D0)
			    }
			    RA_DEC(ret) = HAVE_RA_DEC
			}
		    }
		}
	    }
	    pos = strmatch (COMMENTS(ret, i), "Epoch")
	    if (pos > 0) {
		call strcpy (COMMENTS(ret, i), BUF(1), SZ_COMMENT_FIELD)
		if (sscan (BUF(pos)) != EOF) {
		    call gargd (ms)
		    if (nscan() > 0) {
			EPOCH(dret) = ms
		    }
		}
	    }
	}

	call sfree (sp)
end
