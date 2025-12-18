
//************FORMAT ** WAV**************************
typedef struct
{	int	Sign		__attribute__ ((packed)); // == "RIFF"
	int     SizeFileOQw	__attribute__ ((packed));
	char	Sign2[8]	__attribute__ ((packed)); // == 'WAVEfmt '
	char	Resv[6] 	__attribute__ ((packed));
	short	Type		__attribute__ ((packed));
	int	SamplingSpeed	__attribute__ ((packed));
	int	ByteOutSec	__attribute__ ((packed));
	short	EchantSize	__attribute__ ((packed));
	short	BitEchant	__attribute__ ((packed));
	int	SignDATA	__attribute__ ((packed)); // == 'data'
	unsigned int SizeDATA	__attribute__ ((packed));
} HeadWAV;

// GUI PARAMETERS

#define DGUI_DELAY_REPEAT   0.5
#define DGUI_REPEAT_RATE    15.0

