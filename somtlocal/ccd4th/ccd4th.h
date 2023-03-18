# CCD4TH.H - Definitions for the CCD FORTH format tape reader.

define LEN_USER_AREA		0
define MAX_RANGES		100

define SECS_PER_CYCLE		0.5E-6		# preflash units of 0.5 usec

define NBYTES_PER_PIXEL 	2
define NPIX_PER_RECORD		512
define SZB_FORTH_RECORD 	(NBYTES_PER_PIXEL * (NPIX_PER_RECORD + 1))
define SZ_TEXT_FIELD		24
define SZ_COMMENT_FIELD 	64
define N_BLOCKS_PER_TRACK	6
define N_HEADER_PAD_BLOCKS	(N_BLOCKS_PER_TRACK - 1)
define NPIX_PER_TRACK		(NPIX_PER_RECORD * N_BLOCKS_PER_TRACK)

# The control parameter structure is defined below:

define LEN_CP		(5 + SZ_FNAME + 1)

define LONG_HEADER	Meml[$1]
define MAKE_IMAGE	Meml[$1+1]
define OFFSET		Meml[$1+2]
define DATA_TYPE	Meml[$1+3]
define OVERWRITE	Meml[$1+4]
define IRAF_FILE	Memc[P2C($1+5)]

# The header structure is defined below.  This is used to hold the
# information within the program in structure ccd.

define LEN_CCD	(27 + 7 * (SZ_TEXT_FIELD+1) + (5 * (SZ_COMMENT_FIELD+1)))

define N_DATA_BLOCKS	Meml[$1]	# number of data blocks on tape
define PICTURE_N	Meml[$1+1]	# picture number
define BLOCK_N		Meml[$1+2]	# block number
define N_WORDS		Meml[$1+3]	# number of 16-bit words in data file
define FORTH_DATA_TYPE	Meml[$1+4]
define NPIX		Meml[$1+4+$2]	# number of pixels in $2 dimension
define N_DIM		Meml[$1+8]	# number of dimensions
define RA		Meml[$1+9]	# RA in milli-time-seconds
define DEC		Meml[$1+10]	# Declination in milli-seconds
define START		Meml[$1+11]	# Start time (MST) in milli-seconds
define STOP		Meml[$1+12]	# Stop time (MST) in milli-seconds
define YEAR		Meml[$1+13]
define MONTH		Meml[$1+14]
define DAY		Meml[$1+15]
define SHUTTER		Meml[$1+16]
define PHASE		Meml[$1+17]
define EXP		Meml[$1+18]	# exposure time in milli-seconds
define SID		Meml[$1+19]	# sidereal time in milli-seconds
define HA		Meml[$1+20]	# hour angle in milli-seconds
define AIRMASS		Meml[$1+21]
define TAPE_NO		Meml[$1+22]
define CTEMP		Meml[$1+23]	# CCD temperature (degrees Celcius)
define DTEMP		Meml[$1+24]	# Dewar temperature (degrees Celcius)
define PREFLASH 	Meml[$1+25]	# preflash in cycles of 0.5 usec
define HEADER_NO	Meml[$1+26]

define NAME		Memc[P2C($1+27)] # object name
define CHIP_NAME	Memc[P2C($1+27 + (1 * (SZ_TEXT_FIELD+1)))]
define MODE		Memc[P2C($1+27 + (2 * (SZ_TEXT_FIELD+1)))]
define FILTER		Memc[P2C($1+27 + (3 * (SZ_TEXT_FIELD+1)))]
define DISPERSER	Memc[P2C($1+27 + (4 * (SZ_TEXT_FIELD+1)))]
define TILT		Memc[P2C($1+27 + (5 * (SZ_TEXT_FIELD+1)))]
define APERTURE 	Memc[P2C($1+27 + (6 * (SZ_TEXT_FIELD+1)))]
define COMMENTS 	Memc[P2C($1+27 + (7 * (SZ_TEXT_FIELD+1))+($2-1)*(SZ_COMMENT_FIELD+1))]
					  # 5 lines of comments (1 - 5),
					  #   64 characters each

# BYTE offsets to various CCD FORTH header words are defined below.
# These become word offsets once each byte is unpacked per element
# of an integer array.	These are used to reference the information
# in the header of a CCD frame.

define N_DATA_BLOCKS_OFFSET   ((  0 * 2) + 1)	# number of data blocks on tape
define PICTURE_N_OFFSET       ((  1 * 2) + 1)	# picture number
define BLOCK_N_OFFSET	      ((  2 * 2) + 1)	# block number
define N_WORDS_OFFSET	      ((  3 * 2) + 1)	# number of 16-bit words in data file
define FORTH_DATA_TYPE_OFFSET ((  5 * 2) + 1)
define NPIX2_OFFSET	      ((  6 * 2) + 1)	# number of lines
define NPIX1_OFFSET	      ((  7 * 2) + 1)	# number of columns
define NPIX3_OFFSET	      ((  8 * 2) + 1)	# third dimension
define N_DIM_OFFSET	      ((  9 * 2) + 1)	# number of dimensions
define RA_OFFSET	      (( 10 * 2) + 1)	# RA in milli-time-seconds
define DEC_OFFSET	      (( 12 * 2) + 1)	# Declination in milli-seconds
define START_OFFSET	      (( 14 * 2) + 1)	# Start time (MST) in milli-sec
define STOP_OFFSET	      (( 16 * 2) + 1)	# Stop time (MST) in milli-sec
define YEAR_OFFSET	      (( 18 * 2) + 1)
define MONTH_DAY_OFFSET       (( 19 * 2) + 1)	# month * 100 + day

define SHUTTER_OFFSET	      (( 64 * 2) + 1)
define PHASE_OFFSET	      (( 65 * 2) + 1)
define EXP_OFFSET	      (( 66 * 2) + 1)	# exposure time in milli-seconds
define SID_OFFSET	      (( 68 * 2) + 1)	# sidereal time in milli-seconds
define HA_OFFSET	      (( 70 * 2) + 1)	# hour angle in milli-seconds
define AIRMASS_OFFSET	      (( 72 * 2) + 1)
define TAPE_NO_OFFSET	      (( 73 * 2) + 1)
define CTEMP_OFFSET	      (( 74 * 2) + 1)	# CCD temperature (degrees C)
define DTEMP_OFFSET	      (( 75 * 2) + 1)	# Dewar temperature (degrees C)
define PREFLASH_OFFSET	      (( 76 * 2) + 1)	# preflash in cycles of 0.5 usec

define NAME_OFFSET	      ((256 * 2) + 1)	# object name
define CHIP_NAME_OFFSET       ((266 * 2) + 1)
define MODE_OFFSET	      ((288 * 2) + 1)
define FILTER_OFFSET	      ((298 * 2) + 1)
define DISPERSER_OFFSET       ((308 * 2) + 1)
define TILT_OFFSET	      ((330 * 2) + 1)
define APERTURE_OFFSET	      ((340 * 2) + 1)
define COMMENTS_OFFSET	     (((352+($1-1)*(SZ_COMMENT_FIELD/2)) * 2) + 1)
						# 5 lines of comments (1 - 5),
						#   64 characters each
define HEADER_NO_OFFSET       ((512 * 2) + 1)
