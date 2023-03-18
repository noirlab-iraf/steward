#include <stdio.h>

#define	ZOPNPI	zopnpi_
#define	ZCLSPI	zclspi_
#define	ZARDPI	zardpi_
#define	ZAWRPI	zawrpi_
#define	ZAWTPI	zawtpi_
#define	ZSTTPI	zsttpi_

#define	PI_OPTBUFSIZE	4096
#define	PI_MAXBUFSIZE	4096

#define	import_knames
#define	import_kernel
#define import_spp
#define	import_zfstat
#include <iraf.h>

/*
 * ZFIOPI -- FIO interface to popen.
 */


/* ZOPNPI - Open.
 */
ZOPNPI (name, mode, chan)
PKCHAR	*name;			/* command string		*/
XINT	*mode;			/* file access mode		*/
XINT	*chan;			/* file number (output)		*/
{
	int	fd;
	FILE	*fp;
	char	*fmode;

	switch (*mode) {
	case READ_ONLY:
	    fmode = "r";
	    break;
	case WRITE_ONLY:
	    fmode = "w";
	    break;
	default:
	    *chan = XERR;
	    return;
	}

	if ((fp = popen ((char *)name, fmode)) == NULL) {
	    *chan = XERR;
	    return;
	}
	if ((fd = fileno(fp)) >= MAXOFILES) {
	    pclose (fp);
	    *chan = XERR;
	    return;
	}

	fd = fileno (fp); 
	zfd[fd].fp = fp;
	zfd[fd].fpos = 0;
	zfd[fd].nbytes = 0;
	zfd[fd].io_flags = 0;
	zfd[fd].flags =  KF_NOSEEK | KF_NOSTTY;

	*chan = fd;
	return;
}


/* ZCLSPI -- Close.
 */
ZCLSPI (fd, status)
XINT	*fd;
XINT	*status;
{
	*status = XOK;
	pclose (zfd[*fd].fp);
	zfd[*fd].fp = NULL;
}


/* ZARDPI -- "Asynchronous" read.  Initiate a read of at most
 * maxbytes bytes into the buffer BUF.  Status is returned
 * in a subsequent call to ZAWTPI.
 */
ZARDPI (chan, buf, maxbytes, offset)
XINT	*chan;			/* UNIX file number			*/
XCHAR	*buf;			/* output buffer			*/
XINT	*maxbytes;		/* max bytes to read			*/
XLONG	*offset;		/* 1-indexed file offset to read at	*/
{
	zfd[*chan].nbytes = fread (buf, 1, *maxbytes, zfd[*chan].fp);
}


/* ZAWRPI -- "Asynchronous" write.  Initiate a write of exactly
 * nbytes bytes from the buffer BUF.  Status is returned in a
 * subsequent call to ZAWTPI.
 */
ZAWRPI (chan, buf, nbytes, offset)
XINT	*chan;			/* UNIX file number		*/
XCHAR	*buf;			/* buffer containing data	*/
XINT	*nbytes;		/* nbytes to be written		*/
XLONG	*offset;		/* 1-indexed file offset	*/
{
	zfd[*chan].nbytes = fwrite (buf, 1, *nbytes, zfd[*chan].fp);
	fflush (zfd[*chan].fp);
}


/* ZAWTPI -- "Wait" for an "asynchronous" read or write to complete, and
 * return the number of bytes read or written, or ERR.
 */
ZAWTPI (fd, status)
XINT	*fd;
XINT	*status;
{
	if ((*status = zfd[*fd].nbytes) == ERR)
	    *status = XERR;
}


/* ZSTTPI -- Return status.
 */
ZSTTPI (fd, param, lvalue)
XINT	*fd;
XINT	*param;
XLONG	*lvalue;
{

	switch (*param) {
	case FSTT_BLKSIZE:
	    (*lvalue) = 0L;
	    break;

	case FSTT_FILSIZE:
	    /* The file size is undefined if the file is a streaming file.
	     */
	    (*lvalue) = (-1L);
	    break;

	case FSTT_OPTBUFSIZE:
	    (*lvalue) = PI_OPTBUFSIZE;
	    break;

	case FSTT_MAXBUFSIZE:
	    (*lvalue) = PI_MAXBUFSIZE;
	    break;

	default:
	    (*lvalue) = XERR;
	    break;
	}
}
