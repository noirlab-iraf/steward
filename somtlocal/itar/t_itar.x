include <fset.h>
include <mach.h>

define	SZB_TARBLOCK	512


# ITAR -- Copy a tar tape file.

procedure t_itar ()

int	mtopen(), fopnbf(), read(), clgeti(), mtfile(), open()
int	in, out, bfactor, bufsize, nchars
pointer	sp, namein, nameout, buffer
extern	zopnpi(), zardpi(), zawrpi(), zawtpi(), zsttpi(), zclspi()
errchk	mtopen, fopnbf, read, write, close, open

begin
	call smark (sp)

	call salloc (namein, SZ_FNAME+1, TY_CHAR)
	call clgstr ("in", Memc[namein], SZ_FNAME)
	if (Memc[namein] == '|')
	    in = fopnbf (Memc[namein+1], READ_ONLY,
		zopnpi, zardpi, zawrpi, zawtpi, zsttpi, zclspi)
	else
	    in = mtopen (Memc[namein], READ_ONLY, 0)

	call salloc (nameout, SZ_FNAME+1, TY_CHAR)
	call clgstr ("out", Memc[nameout], SZ_FNAME)
	if (Memc[nameout] == '|')
	    out = fopnbf (Memc[nameout+1], WRITE_ONLY,
		zopnpi, zardpi, zawrpi, zawtpi, zsttpi, zclspi)
	else if (mtfile (Memc[nameout]) == YES)
	    out = mtopen (Memc[nameout], WRITE_ONLY, 0)
	else
	    out = open (Memc[nameout], NEW_FILE, BINARY_FILE)

	bfactor = clgeti ("blocking_factor")
	bufsize = bfactor * SZB_TARBLOCK / SZB_CHAR
	call salloc (buffer, bufsize, TY_CHAR)
	call fseti (in, F_BUFSIZE, bufsize)
	call fseti (out, F_BUFSIZE, bufsize)

	repeat {
	    nchars = read (in, Memc[buffer], bufsize)
	    if (nchars == EOF)
		break
	    call write (out, Memc[buffer], nchars)
	}

	call close (in)
	call close (out)
	call sfree (sp)
end
