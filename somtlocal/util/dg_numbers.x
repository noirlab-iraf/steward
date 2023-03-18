include <ctype.h>

# DG_NUMBERS.X - Routines to convert Data General numbers portably.
#
# Input values should be 1 unsigned byte per SPP long array element.


# DG_CHAR_TO_CHAR - pack up a character string.
# The sequence of 7 bit characters are terminated by a NULL (EOS).
# Any trailing whitespace is removed.

procedure dg_char_to_char (inbuf, offset, length, output_string)

long	inbuf[ARB]	# unpacked byte array
int	offset		# WORD offset in inbuf which designates the
			#   first byte of the DG string
int	length		# maximum length of the string, in case there is
			#   no NULL
char	output_string[length+1]
			# output array - one character per element

int	i, slen

begin
	slen = 0
	do i = 1, length {
	    output_string[i] = mod (inbuf[i-1+offset], 200b)
	    if (output_string[i] == EOS) {
		slen = i
		break
	    }
	}

	# slen is the location of EOS or 0 if none were encountered.
	if (slen == 0) {
	    output_string[length+1] = EOS
	    slen = length + 1
	}

	slen = slen - 1			# location of last character

	# trim trailing whitespace
	do i = slen , 1, -1 {
	    if (!IS_WHITE (output_string[i]))
		break
	    output_string[i] = EOS
	}
end


# DG_DFLOAT_TO_DOUBLE - assemble a double from 8 DG bytes (double precision
# floating point.

procedure dg_dfloat_to_double (inbuf, offset, value)

long	inbuf[ARB]	# unpacked byte array
int	offset		# WORD offset in inbuf which designates the first
                        #   byte of the DG double precision floating point number
double	value		# double floating point value returned

int	sign, exp, i
long	bytes[8]

begin
	call amovl (inbuf[offset], bytes, 8)

	# check for zero
	if (bytes[2] == 0) {		# number must be normalized
	    value = 0.D0
	    return
	}

	# get the sign and exponent (excess 64)
	if (bytes[1] >= (2**7)) {
	    sign = -1
	    exp = bytes[1] - (2**7)
	} else {
	    sign = 1
	    exp = bytes[1]
	}

	# evaluate the mantissa
	value = 0.D0
	do i = 8, 2, -1
	    value = (value + double (bytes[i])) / 256.D0

	# assemble the pieces
	value = value * (16.D0 ** (exp - 64))
	if (sign == -1)
	    value = -value

	return
end


# DG_NUINT_TO_LONG - assemble a sequence of long integers from pairs of DG
# bytes (unsigned).

procedure dg_nuint_to_long (inbuf, outbuf, n)

long	inbuf[ARB]	# unpacked byte array
long	outbuf[ARB]	# output buffer to receive 'n' long integers.
			#   This may be the same as inbuf.
int	n		# number of unsigned integers to assemble.

int	offset, outp

begin
	offset = 1
	do outp = 1, n {
	    outbuf[outp] = inbuf[offset+1] + ((2**8) * inbuf[offset])
	    offset = offset + 2
	}
end


# DG_SINT_TO_LONG - assemble a long integer from 2 DG bytes (signed).

procedure dg_sint_to_long (inbuf, offset, value)

long	inbuf[ARB]	# unpacked byte array
int	offset		# WORD offset in inbuf which designates the
			#   first byte of the DG integer
long	value		# long integer value returned

long	bytes[2]

begin
	bytes[1] = inbuf[offset]
	bytes[2] = inbuf[offset+1]
	if (bytes[1] >= (2**7))
	    bytes[1] = bytes[1] - (2**8)
	value = bytes[2] + ((2**8) * bytes[1])
end


# DG_SLONG_TO_LONG - assemble a long integer from 4 DG bytes (signed).

procedure dg_slong_to_long (inbuf, offset, value)

long	inbuf[ARB]	# unpacked byte array
int	offset		# WORD offset in inbuf which designates the
			#   first byte of the DG integer
long	value		# long integer value returned

long	bytes[4]

begin
	call amovl (inbuf[offset], bytes, 4)
	if (bytes[1] >= (2**7))
	    bytes[1] = bytes[1] - (2**8)
	value = bytes[4] + ((2**8) * (bytes[3] +
			((2**8) * (bytes[2] + ((2**8) * bytes[1])))))
end


# DG_UBYTE_TO_LONG - convert an unsigned byte value to a long integer

procedure dg_ubyte_to_long (inbuf, offset, value)

long	inbuf[ARB]	# unpacked byte array
int	offset		# WORD offset in inbuf which designates the
			#   byte to convert
long	value		# long integer value returned

begin
	value = inbuf[offset]
end


# DG_UINT_TO_LONG - assemble a long integer from 2 DG bytes (unsigned).

procedure dg_uint_to_long (inbuf, offset, value)

long	inbuf[ARB]	# unpacked byte array
int	offset		# WORD offset in inbuf which designates the
			#   first byte of the DG integer
long	value		# long integer value returned

begin
	value = inbuf[offset+1] + ((2**8) * inbuf[offset])
end


# DG_ULONG_TO_LONG - assemble a long integer from 4 DG bytes (unsigned).

procedure dg_ulong_to_long (inbuf, offset, value)

long	inbuf[ARB]	# unpacked byte array
int	offset		# WORD offset in inbuf which designates the
			#   first byte of the DG integer
long	value		# long integer value returned

begin
	value = inbuf[offset+3] + ((2**8) * (inbuf[offset+2] +
		    ((2**8) * (inbuf[offset+1] + ((2**8) * inbuf[offset])))))
end
