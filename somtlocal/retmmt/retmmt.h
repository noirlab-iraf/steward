# RETMMT.H - Definitions for the MMT Reticon format tape reader.

define LEN_USER_AREA		0
define MAX_RANGES		100

define NBYTES_PER_PIXEL 	2
define SZ_TEXT_FIELD		8
define SZ_COMMENT_FIELD 	64
define SZ_LABEL			60

define LEN_ID_REC		512	# length of id record in bytes
define DATLEN 			8192	# length of data in bytes
define TOTLEN 			9728	# length of data + header info in bytes
define COMM_OFF               (DATLEN)  # offset to comments
define HEAD_OFF       (COMM_OFF + 1024) # offset to header information

define LABEL_TYPE		17733	# type for tape label record
define HEADER_TYPE		0	# type for header record
define NO_RA_DEC		0	# no RA and DEC info
define HAVE_RA_DEC		1
define STOW_RA_DEC		2	# RA and DEC are at stow position

# The control parameter structure is defined below:

define LONG_HEADER	Meml[$1]
define MAKE_IMAGE	Meml[$1+1]
define DATA_TYPE	Meml[$1+2]
define OVERWRITE	Meml[$1+3]
define START_NUMBER	Meml[$1+4]
define SEQ_NUMBER	Meml[$1+5]
define NFILES		Meml[$1+6]
define FRANGE   	Meml[$1+7]
define DRANGE   	Meml[$1+7+1*3*MAX_RANGES]
define PRANGE   	Meml[$1+7+2*3*MAX_RANGES]

define LEN_CP		(7 + 3*3*MAX_RANGES)

# The header structure is defined below.  These are used to hold the
# information within the program in structures ret and dret.

define JDN		Memd[$1] 	# Julian day number
define EPOCH		Memd[$1+1]	# epoch of position
define LEN_DRET		2

define REV_N            Meml[$1]	# revision number of header
define DISK_N		Meml[$1+1]	# raw data disk number
define FILE_N  		Meml[$1+2]	# raw data file number
define LOCAL_T		Meml[$1+3]	# local time in milli-seconds
define SID_T		Meml[$1+4]	# sidereal time in milli-seconds
define YEAR		Meml[$1+5]
define MONTH		Meml[$1+6]
define DAY		Meml[$1+7]
define SITE		Meml[$1+8]
define BEAM		Meml[$1+9]
define EXP_TIME		Meml[$1+10]	 # exposure time in seconds
define RA_DEC		Meml[$1+11]	 # form of RA and DEC
define RA		Meml[$1+12]	 # RA in milliseconds of time
define DEC		Meml[$1+13]	 # DEC in milliseconds of arc
define NDATA		Meml[$1+14]	 # length of data array in pixels

define FILE_ID		Memc[P2C($1+15)] # object name
define LABEL    	Memc[P2C($1+15+(1*(SZ_TEXT_FIELD+1)))]
define OBJECT   	Memc[P2C($1+15+(1*(SZ_TEXT_FIELD+1))+(1*(SZ_LABEL+1)))]
define SITE_NAME	Memc[P2C($1+15+(1*(SZ_TEXT_FIELD+1))+(2*(SZ_LABEL+1)))]
define COMMENTS 	Memc[P2C($1+15+(1*(SZ_TEXT_FIELD+1))+(3*(SZ_LABEL+1))+($2-1)*(SZ_COMMENT_FIELD+1))]
					  # 16 lines of comments (1 - 16),
					  #   64 characters each

define LEN_RET	(15+(1*(SZ_TEXT_FIELD+1))+(3*(SZ_LABEL+1))+(16*(SZ_COMMENT_FIELD+1)))

# BYTE offsets to various MMT Reticon header words are defined below.
# These become word offsets once each byte is unpacked per element
# of an integer array.

# id record

define TYPE_OFFSET	      (( 0 * 2) + 1)	  # type of header
define IFILE_ID_OFFSET	      (( 5 * 2) + 1)	  # file name:
						  #   character count and 7 characters
define NREC_OFFSET	      (( 9+($1-1)*2)*2+1) # number of records [1...]
define LREC_OFFSET	      ((10+($1-1)*2)*2+1) # length of records [1...]

# tape label record

define TAPE_LABEL_OFFSET      (( 5 * 2) + 1)	  # tape name:
						  #   character count and 7 characters

# fixed point parameters record

define REV_OFFSET     (HEAD_OFF+( 0 * 2) + 1)	# revision number [0 .. 3]
define LSTM_OFFSET    (HEAD_OFF+( 1 * 2) + 1)	# local standard time (min)
define EXP_OFFSET     (HEAD_OFF+( 2 * 2) + 1)	# exposure time (sec)
define MONTH_OFFSET   (HEAD_OFF+( 3 * 2) + 1)
define DAY_OFFSET     (HEAD_OFF+( 4 * 2) + 1)
define YEAR_OFFSET    (HEAD_OFF+( 5 * 2) + 1)
define STM_OFFSET     (HEAD_OFF+( 6 * 2) + 1)	# sidereal time (min)
define LSTS_OFFSET    (HEAD_OFF+( 7 * 2) + 1)	# local standard time (0.1 sec)
define STS_OFFSET     (HEAD_OFF+( 8 * 2) + 1)	# sidereal time (0.1 sec)
define JDN_OFFSET     (HEAD_OFF+( 9 * 2) + 1)	# 8 byte Data General fp number

define DISK_OFFSET    (HEAD_OFF+(14 * 2) + 1)
define FILE_OFFSET    (HEAD_OFF+(15 * 2) + 1)
define SITE_OFFSET    (HEAD_OFF+(16 * 2) + 1)	# site [0 .. 2]

define FILE_ID_OFFSET (HEAD_OFF+(18 * 2) + 1)	# file name:
						#   character count and 7 characters

define BEAM_OFFSET    (HEAD_OFF+(22 * 2) + 1)	# beam [0 .. 2]

# comment record

define COMMENTS_OFFSET (COMM_OFF+((0+($1-1)*(SZ_COMMENT_FIELD/2)) * 2) + 1)
						# 16 lines of comments (1 - 16),
						#   64 characters each
