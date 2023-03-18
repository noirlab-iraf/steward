define	MAXLEN_STRVAL	65
define	LEN_KEYWORD	8
define	LEN_STRING	18

# ADDCARD_R -- Format and append a FITS header card with a real
# keyword value to the input string buffer.  

procedure addcard_r (fd, keyword, value, comment, precision)

int	fd			# File descriptor of input string buffer
char	keyword[LEN_KEYWORD]	# FITS keyword
real	value			# Value of FITS keyword
char	comment[ARB]		# Comment string
int	precision		# Number of significant digits output

begin
	call fprintf (fd, "%-8.8s= %20.*g  /  %-45.45s\n")
	    call pargstr (keyword)
	    call pargi (precision)
	    call pargr (value)
	    call pargstr (comment)
end


# ADDCARD_I -- Format and append a FITS header card with an integer
# keyword value to the input string buffer.

procedure addcard_i (fd, keyword, value, comment)

int	fd			# File descriptor of input string buffer
char	keyword[LEN_KEYWORD]	# FITS keyword
int	value			# Value of FITS keyword
char	comment[ARB]		# Comment string

begin
	call fprintf (fd, "%-8.8s= %20d  /  %-45.45s\n")
	    call pargstr (keyword)
	    call pargi (value)
	    call pargstr (comment)
end


# ADDCARD_TIME -- Format and append a FITS header card to the input
# file descriptor.  The value is input as a double number; it is output
# in HH:MM:SS.S format with %h.  The procedure can be used for RA, DEC
# and ST, UT and HA.

procedure addcard_time (fd, keyword, dvalue, comment)

int	fd			# File descriptor
char	keyword[LEN_KEYWORD]	# FITS keyword
double	dvalue			# Value of FITS keyword to be encoded
char	comment[ARB]		# Comment string

begin
	if (dvalue < 0.d0) {
	    call fprintf (fd, "%-8.8s= '-%-17.1h'  /  %-45.45s\n")
	        call pargstr (keyword)
	        call pargd (-dvalue)
	        call pargstr (comment)
	} else {
	    call fprintf (fd, "%-8.8s= '%-18.1h'  /  %-45.45s\n")
	        call pargstr (keyword)
	        call pargd (dvalue)
	        call pargstr (comment)
	}
# The following 4 lines should replace all the above when %h for negative
# values works properly.  These 4 lines are the whole routine.
#	call fprintf (fd, "%-8.8s= '%-18.1h'  /  %-45.45s\n")
#	    call pargstr (keyword)
#	    call pargd (dvalue)
#	    call pargstr (comment)
end


# ADDCARD_ST -- Format and output a FITS header card to the input
# file descriptor.  The value is output as a string with the given keyword.
# If the string value is longer than 18 characters, it is output without
# a comment.

procedure addcard_st (fd, keyword, value, comment, length)

int	fd			# File descriptor
char	keyword[LEN_KEYWORD]	# FITS keyword
char	value[SZ_LINE]		# String value of FITS keyword to be encoded
char	comment[ARB]		# Comment string
int	length			# Length of string value

begin	
	if (length <= LEN_STRING) {
	    call fprintf (fd, "%-8.8s= '%-18.18s'  /  %-45.45s\n")
		call pargstr (keyword)
		call pargstr (value)
		call pargstr (comment)
	} else	{
	    length = min (length, MAXLEN_STRVAL)
	    call fprintf (fd, "%-8.8s= '%*.*s'  /\n")
		call pargstr (keyword)
		call pargi (-length)
		call pargi (length)
		call pargstr (value)
	}
end


# ADDCARD_B -- Format and output a FITS header card to the input file
# descriptor.  The value is output as a boolean with the given keyword.
# Unlike string parameters, booleans are not enclosed in quotes.

procedure addcard_b (fd, keyword, value, comment)

int	fd			# File descriptor
char	keyword[LEN_KEYWORD]	# FITS keyword
bool	value			# Boolean parameter (T/F)
char	comment[ARB]		# Comment string
char	truth

begin
	if (value)
	    truth = 'T'
	else
	    truth = 'F'

	call fprintf (fd, "%-8.8s= %20c  /  %-45.45s\n")
	    call pargstr (keyword)
	    call pargc (truth)
	    call pargstr (comment)
end


# ADDCARD_D -- Format and append a FITS header card with a double
# keyword value to the input string buffer.  

procedure addcard_d (fd, keyword, value, comment, precision)

int	fd			# File descriptor of input string buffer
char	keyword[LEN_KEYWORD]	# FITS keyword
double	value			# Value of FITS keyword
char	comment[ARB]		# Comment string
int	precision		# Number of significant digits output

begin
	call fprintf (fd, "%-8.8s= %20.*g  /  %-45.45s\n")
	    call pargstr (keyword)
	    call pargi (precision)
	    call pargd (value)
	    call pargstr (comment)
end


# ADDCARD_COM -- Format and append a FITS header card of a comment.
# The comment keyword may be COMMENT, HISTORY, or blank.

procedure addcard_com (fd, keyword, comment)

int	fd			# File descriptor of input string buffer
char	keyword[LEN_KEYWORD]	# FITS keyword
char	comment[ARB]		# Comment string

begin
	call fprintf (fd, "%-8.8s %-71.71s\n")
	    call pargstr (keyword)
	    call pargstr (comment)
end
