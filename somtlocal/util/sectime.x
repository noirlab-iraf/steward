include <time.h>

# SECTIME.X - Convert a time structure to seconds since 00:00:00 01 Jan 1980.
#
# The time structure fields which are needed are TM_(SEC, MIN, HOUR, MDAY,
# MONTH, and YEAR).  The other fields TM_WDAY and TM_YDAY are not used.

define SECONDS_PER_DAY	86400
define FEBRUARY 	2
define BEGIN_YEAR	long (1980)


long procedure sectime (tm)

int	tm[LEN_TMSTRUCT]

int	i
long	sec, n
int	days_per_month[12]
data	days_per_month /31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31/

begin
	if (abs (TM_YEAR(tm) - BEGIN_YEAR) > 50) {
	    call eprintf ("bad year = %d\n")
		call pargi (TM_YEAR(tm))
	    return (0)
	}

	sec = TM_SEC(tm) + 60 * (TM_MIN(tm) + 60 * (TM_HOUR(tm) +
			   24 * (TM_MDAY(tm) - 1)))

	if (mod (TM_YEAR(tm), 4) == 0)
	    if (mod (TM_YEAR(tm), 100) == 0)
		if (mod (TM_YEAR(tm), 400) == 0)
		    days_per_month[FEBRUARY] = 29
		else
		    days_per_month[FEBRUARY] = 28
	    else
		days_per_month[FEBRUARY] = 29
	else
	    days_per_month[FEBRUARY] = 28

	n = 0
	if (TM_MONTH(tm) >= 1 && TM_MONTH(tm) <= 12)
	    do i = 1, TM_MONTH(tm) - 1
	        n = n + days_per_month[i]

	sec = sec + n * SECONDS_PER_DAY

	n = (long (TM_YEAR(tm)) - (BEGIN_YEAR - 3)) / 4   # number of leap years
						          #	before this year
	sec = sec + (365 * (long(TM_YEAR(tm))-BEGIN_YEAR) + n) * SECONDS_PER_DAY
	return (sec)
end
