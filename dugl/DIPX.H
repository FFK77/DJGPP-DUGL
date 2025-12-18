#ifndef DIPX_H

#define DIPX_H
//******* IPX ********************************************************
typedef struct
{	unsigned char  Network[4];
} IPXNetwork;

typedef struct
{	unsigned char  Node[6];
} IPXNode;

typedef struct
{	unsigned short Socket;
} IPXSocket;

typedef struct
{	IPXNetwork     Network;
	IPXNode        Node;
} IPXAddress;

typedef struct
{	unsigned short Checksum,
		       Length;
	unsigned char  TransportControl,
		       Type;
	IPXNetwork     DNetwork;
	IPXNode        DNode;
	IPXSocket      DSocket;
	IPXNetwork     SNetwork;
	IPXNode        SNode;
	IPXSocket      SSocket;
} IPXPacket;

typedef struct
{	int	       Sign;    // =="VECB"
	unsigned char  InUse,
		       CompletitionCode;
	IPXSocket      Socket;
	IPXNode	       ImmediateAddress;
	IPXPacket      Packet;
	unsigned short MaxSize;
	int	       ECBSel;
	unsigned short OffRmECB,
		       SegRmECB;
} IPXECB;

//**************************************************************************
//******** IPX ******* ipxc.c - ipx.asm ************************************
//**************************************************************************
#ifdef __cplusplus
extern "C" {
#endif

#define IPX_Assign_Socket 0
// IPX send Packet Type
#define IPX_UNKNWN_PACK_TYPE 		0x0
#define IPX_ROUTING_PACK_TYPE 		0x1
#define IPX_ECHO_PACK_TYPE 		0x2
#define IPX_ERROR_PACK_TYPE 		0x3
#define IPX_EXCHANGE_PACK_TYPE 		0x4  // always use this for data
#define IPX_SPX_PACK_TYPE 		0x5  // SPX PAcket
#define IPX_NETWARE_CORE_PACK_TYPE	0x11 // Netware core
#define IPX_PROPAGATE_PACK_TYPE		0x14 // Propagated (netWare), name packet (NetBIOS)

extern IPXAddress MyIPXAddress;
extern IPXNode IPXAllNodes;
extern IPXNetwork IPXSameNetwork;

int  InitIPX();
int  DetectIPX();
unsigned short GetIPXMaxPacketSize();
unsigned short GetIPXMaxDataSize();
void GetIPXInterNetworkAddress(IPXAddress *Address);
int  IPXOpenSocket(IPXSocket *Socket);
void IPXCloseSocket(IPXSocket *Socket);
void IPXRelinquishControl();
int  CreateECB(IPXECB **ECB,unsigned short MaxDataSize);
void DestroyECB(IPXECB *ECB);
int  GetECB(IPXECB *ECB);
unsigned short GetECBData(IPXECB *ECB,void *Data);
int  IPXSendPacket(IPXECB *ECB,IPXNetwork *Network,IPXNode *Node,IPXSocket *Socket,
                   unsigned char Type,void *Data,unsigned short SizeData);
int  IPXListenPacket(IPXECB *ECB,IPXSocket *Socket);
int  IPXCancelECB(IPXECB *ECB);

#ifdef __cplusplus
           }
#endif

#endif   // #ifndef DIPX_H
