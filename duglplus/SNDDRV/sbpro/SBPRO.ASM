SECTION .text
[BITS 32]
; DRIVER HEADER ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Signature		DD	"FSDR"		; FLAT SOUND DRIVER
SizeDrv			DD	FinDrv
Capabilities		DD	Out8|OutMono|OutStereo|In8|InMono|InStereo
Capabilities2		DD	0
SizeBuff		DD	SizeDMABuff*6
Min8BitMono		DD	4000
Max8BitMono		DD	45454
Min16BitMono		DD	0
Max16BitMono		DD	0
Min8BitStereo		DD	4000
Max8BitStereo		DD	22727
Min16BitStereo		DD	0
Max16BitStereo		DD	0
SB_BasePort		DD	0
SB_IRQ			DD	0
SB_DMA8			DD	0
SB_DMA16		DD	0
SB_SampSpeed		DD	0
LastError		DD	0
Version			DD	'0500' ; version 0.5
resv:			DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			DD	0,0,0,0,0,0,0,0
DrvBuffPtr		DD	0
PtrCardName		DD	CardName
GlobFonc:		DD	InitDriver,InstallDriver,UninstallDriver
			DD	InitSound,ResetSound,StopSound,ContinueSound
			DD	SetMasterVolume,SetVoiceVolume,SetMidiVolume
			DD	SetCDVolume,SetLineVolume,SetMicVolume
			DD	SetInGain,SetOutGain,SetAutoGain,SetTreble
			DD	SetBass,SetOutput,SetInput
			DD	NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
VoiceMixer:		DD	AddVoice,PrepVoice,UnprepVoice,GetVoiceState
			DD	SetVoiceState,GetVoiceEffPack,SetVoiceEffPack
			DD	GetVoicePos,SetVoicePos,DeleteVoice
			DD	DeleteAllVoice,GetNbVoice
			DD	NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS
			DD	NS,NS,NS,NS,NS,NS,NS,NS

; CODE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%include "param.mac"
DebSndLockCode:;*************************************************************
%include "sb.asm"
%include "dma.asm"
%include "vc_mix.asm"
%include "mixer.asm"

GetBaseAddress:
		MOV		EBX,0
		RET

NS:		; function ((N)ot (S)upported) return 1 in EAX
		MOV		EAX,1
		RET

ALIGN 32
SB_Handler:
		PUSHF
		PUSHAD
		PUSH		DS
		PUSH		ES

		CALL		GetBaseAddress
		MOV		DS,[CS:EBX+SndMyDSSelector]
		MOV		ES,[EBX+SndMyDSSelector]

;***************Procede la E/S 8 Bits**********************

		CALL		GetBaseAddress
		MOV		EAX,[EBX+AddrProced8Bit]
		CALL		EAX

;***************FIN Precede E/S 8 Bits*********************
		CALL		GetBaseAddress
		MOV		EAX,[EBX+OffResCalcDMA8]
		ADD		EAX,SizeDMABuff/2
		AND		EAX,SizeDMABuff-1
		MOV		[EBX+OffResCalcDMA8],EAX
		MOV		EDX,[EBX+DSPStateAck8]
		IN		AL,DX               ; ack 8 Bits
.PasTrait8Bit:

		MOV		AL,0x20
		CALL		GetBaseAddress
                CMP             BYTE [SbIRQ+EBX],8
                JB              .PasContrl2
		OUT		0xA0,AL
.PasContrl2:	OUT		0x20,AL

		POP		ES
		POP		DS
		POPAD
		POPF
		STI
		IRET

FinSndLockCode:;*************************************************************

ResetSound:
		PUSH		EBX
		PUSH		ESI
		PUSH		EDI

		; reset DSP
		CALL		GetBaseAddress
		MOV		EDI,[EBX+SB_BasePort]
		@DetectSBBase 	EDI
                
		; stop SOUND & transfert DMA -------------------------------
		@Write_DSP 0xD0  ; halt operation DMA 8bits
		@Write_DSP 0xDA  ; exit auto-init DMA 8bits
		@StopDMA8
		; Sampling Speed -------------------------------------------
		CALL		GetBaseAddress
		XOR		EAX,EAX
		MOV		[EBX+SB_SampSpeed],EAX
		MOV		[EBX+SbSampSpeed],EAX
		
		; Clear All voices -----------------------------------------
		MOV		ECX,32*2
		LEA		EDI,[VoicePtr+EBX] ; PtrVoix+BaseAddress
		XOR		EAX,EAX
		REP		STOSD

		POP		EDI
		POP		ESI
		POP		EBX
		RET

StopSound:
		PUSH		EBX
		PUSH		ESI
		PUSH		EDI
		@Write_DSP 0xD0
		POP		EDI
		POP		ESI
		POP		EBX
		RET
		
ContinueSound:
		PUSH		EBX
		PUSH		ESI
		PUSH		EDI
		@Write_DSP 0xD4
		POP		EDI
		POP		ESI
		POP		EBX
		RET

SetMasterVolume:
	ARG 	LeftMasterVol, 4, RightMasterVol, 4
		PUSH		EBX

                MOV             CL,0x11
		MOV		DL,[EBP+LeftMasterVol]
		SHR		DL,4
		SHL		DL,4
                OR              CL,DL
		MOV		DL,[EBP+RightMasterVol]
		SHR		DL,4
                OR              CL,DL
		@Write_Mixer 	0x22,CL
                
		POP		EBX
		RETURN

SetVoiceVolume:
	ARG 	LeftVoiceVol, 4, RightVoiceVol, 4
		PUSH		EBX
                MOV             CL,0x11
		MOV		EDX,[EBP+LeftVoiceVol]
		SHR		DL,4
		SHL		DL,4
                OR              CL,DL
		MOV		EDX,[EBP+RightVoiceVol]
		SHR		DL,4
                OR              CL,DL
		@Write_Mixer 	0x04,CL
		POP		EBX
		RETURN

SetMidiVolume:
	ARG 	LeftMidiVol, 4, RightMidiVol, 4
		RETURN

SetCDVolume:
	ARG 	LeftCDVol, 4, RightCDVol, 4
		RETURN

SetLineVolume:
	ARG 	LeftLineVol, 4, RightLineVol, 4
		RETURN

SetMicVolume:
	ARG 	MicVol, 4
		RETURN


SetInGain:
	ARG 	LeftInGainControl, 4, RightInGainControl, 4
		RETURN

SetOutGain:
	ARG 	LeftOutGainControl, 4, RightOutGainControl, 4
		RETURN

SetAutoGain:
	ARG	AutoGainControl, 4
		RETURN

SetTreble:
	ARG 	LeftTreble, 4, RightTreble, 4
		RETURN

SetBass:
	ARG 	LeftBass, 4, RightBass, 4
		RETURN

SetOutput:
	ARG	SelectOutput, 4
		PUSH		EBX
		MOV		CL,[EBP+SelectOutput]
		AND		CL,0x1F
		@Write_Mixer	0x3C,CL
		POP		EBX
		RETURN

SetInput:
	ARG	SelectInputLeft, 4,SelectInputRight, 4
		PUSH		EBX
		MOV		CL,[EBP+SelectInputLeft]
		AND		CL,0x7F
		@Write_Mixer	0x3D,CL
		MOV		CL,[EBP+SelectInputRight]
		AND		CL,0x7F
		@Write_Mixer	0x3E,CL
		POP		EBX
		RETURN
		
;----------------------------------------------------------------------------
; Type..Bits      : 0, (no sound), 1 Out, 2 In
; GenType         : 0 MONO, 1 STEREO
; SampleSpeed     : Sampling Speed ------------------------------------------

InitSound:
	ARG	Type8Bits, 4, Type16Bits, 4, GenType, 4, SampleSpeed, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		CALL		GetBaseAddress	  ; In & Out Type nosound
		MOV		EAX,-1
		MOV		[EBX+InType],EAX
		MOV		[EBX+OutType],EAX
		LEA		ECX,[EBX+NS]
		MOV		[EBX+AddrProced8Bit],ECX   ; non supporte

		@StopDMA8
		; Efface Les Buffer DMA d'E/S-------------------------------
		PUSH		ES
		CALL		GetBaseAddress
		MOV		EAX,0x80808080
		MOV		ECX,SizeDMABuff/4
		MOV		ES,[EBX+SelectorDMA8]
		XOR		EDI,EDI
		REP		STOSD		   ; Efface Buffer DMA8
		POP		ES
                ; set sampling speed -----------------------------------
		@Write_DSP 0x40
                MOV             ECX,[EBP+SampleSpeed]
		CMP		BYTE [EBP+GenType], BYTE 1
		JNE		.MonoSamp8Bit
                SHL             ECX,1 ; *=2 : stereo
.MonoSamp8Bit:  MOV             EAX,1000000
                CDQ
                IDIV            ECX
                NEG             EAX
                ADD             EAX,256 ; = (256 - 1000 000/rate)
                @Write_DSP      AL
                ; sb size DMA buffer ------------------------------------
		@Write_DSP 0x48
        	@Write_DSP (( (SizeDMABuff/2)-1)&0xff)
		@Write_DSP ((( (SizeDMABuff/2)-1)>>8)&0xff)
		; Traitement 8 Bits------------------------------------------
		MOV		EAX,[EBP+Type8Bits]
		MOV		DWORD [EBX+State8Bits],0
		OR		EAX,EAX
		JZ		NEAR .No8BitsSound
		CMP		EAX,BYTE 2
		JE		.In8Bit
.Out8Bit:;--------------------------------------------
		@Write_DSP 0xD1  ; enable speaker
		@StartDMA8 0x58  ; demarre DMA 8 en lecture auto-init

		CMP		[EBP+GenType], BYTE 1
		JE		.StereoOut8Bit
		MOV		DWORD [EBX+OutType],0
		LEA		EAX,[EBX+ProcedOut8BitsM] ; AddrProced ------
		MOV		[EBX+AddrProced8Bit],EAX
                @Write_Mixer    0x0E,0 ; Sbpro mixer enable MONO
		
		JMP		.EndOut8BitMS
.StereoOut8Bit:
		MOV		DWORD [EBX+OutType],1
		LEA		EAX,[EBX+ProcedOut8BitsS] ; AddrProced ------
		MOV		[EBX+AddrProced8Bit],EAX
                @Write_Mixer    0x0E,2 ; Sbpro mixer enale Stereo
.EndOut8BitMS:

                ; start high-speed DAC
		@Write_DSP 0x90  ; Out 8 Bit AutoInit
		JMP		.Size8Bits
.In8Bit:;---------------------------------------------
		@StartDMA8 0x54  ; Ecriture AutoInit
                
		@Write_DSP 0x98  ; In 8 Bit AutoInit
		CMP		[EBP+GenType], BYTE 1
		JE		.StereoIn8Bit
		MOV		DWORD [EBX+InType],0
		LEA		EAX,[EBX+ProcedIn8BitsM] ; AddrProced -------
		MOV		[EBX+AddrProced8Bit],EAX
		JMP		.Size8Bits
.StereoIn8Bit:
		MOV		DWORD [EBX+InType],1
		LEA		EAX,[EBX+ProcedIn8BitsS] ; AddrProced -------
		MOV		[EBX+AddrProced8Bit],EAX

.Size8Bits:	MOV		DWORD [EBX+OffResCalcDMA8],0
.No8BitsSound:

		; Sampling Speed -------------------------------------------
		MOV		EAX,[EBP+SampleSpeed]
		MOV		[EBX+SB_SampSpeed],EAX
		MOV		[EBX+SbSampSpeed],EAX
		
		; clear all voices on queue --------------------------------
		MOV		ECX,32*2
		LEA		EDI,[VoicePtr+EBX] ; PtrVoix+BaseAddress
		XOR		EAX,EAX
		REP		STOSD

		JMP		SHORT .InitSndOk
.InitSndError:	XOR		EAX,EAX
		JMP		NEAR .PasInitSOk
.InitSndOk:	OR		EAX,BYTE -1
.PasInitSOk:
		POP		EBX
		POP		EDI
		POP		ESI
		RETURN

InitDriver:
		PUSH		EBP
		PUSH		EBX
		PUSH		ESI
		PUSH		EDI

		; Patch adresses of the drivers functions--- ***** ----------
		; and patch GetBaseAddress ----------------------------------
		CALL		.BaseAdressEIP  ; Base adress dans la pile
.BaseAdressEIP:	POP		EBX
		SUB		EBX,.BaseAdressEIP
		; patche l'instruction  MOV EBX,(0 -> adress base)
		MOV		[EBX+GetBaseAddress+1],EBX

                ; patch pointer or adresses of the driver functions
                ; cardName + 64 glob Functions + 128 mixer functions
		LEA		ESI,[EBX+PtrCardName]
		MOV		ECX,193
.BcPatchAdd:	ADD		[ESI],EBX
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.BcPatchAdd

		; Patch adresses of the mixing functions
		; to the the main buffer
		LEA		ESI,[EBX+AddrProcAddBCalc]
		MOV		ECX,10
.BcPatchAddBCl:	ADD		[ESI],EBX
		DEC		ECX
		LEA		ESI,[ESI+4]
		JNZ		.BcPatchAddBCl

		POP		EDI
		POP		ESI
		POP		EBX
		POP		EBP
		RET

InstallDriver:
	ARG	PtrBuff, 4, Base, 4, IRQ, 4, DMA8, 4, DMA16, 4
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		; SbPro Detection ------------------------------------------
		CMP		DWORD [EBP+Base], -1
		JE		.AutoDetectBase
		MOV		EDI,[EBP+Base]
		@DetectSBBase 	EDI
		OR		EAX,EAX
		JNZ		.SbDetected
		JMP		SHORT .SbNotDetected
.AutoDetectBase:
		MOV		EDI,0x210; EDI pas utiliser par @DetectSBBase
.BcDtctBase:	@DetectSBBase 	EDI
		OR		EAX,EAX
		JNZ		.SbDetected
		ADD		EDI,BYTE 0x10
		CMP		EDI,0x270
		JNE		.PasIncDetect
		ADD		EDI,BYTE 0x10
.PasIncDetect:
		CMP		EDI,0x290
		JNE		.BcDtctBase
.SbNotDetected:	JMP		.SoundError
.SbDetected:	CALL		GetBaseAddress
		MOV		[EBX+SbBase],EDI
		MOV		[EBX+SB_BasePort],EDI
		LEA		ECX,[EDI+0x4]
		MOV		[EBX+MixerIndex],ECX
		LEA		ECX,[EDI+0x5]
		MOV		[EBX+MixerData],ECX
		LEA		ECX,[EDI+0x6]
		MOV		[EBX+DSPReset],ECX
		LEA		ECX,[EDI+0xA]
		MOV		[EBX+DSPData],ECX
		LEA		ECX,[EDI+0xC]
		MOV		[EBX+DSPStateCommand],ECX
		LEA		ECX,[EDI+0xE]
		MOV		[EBX+DSPStateAck8],ECX
		@Write_DSP 	0xE1	 ; Verif blaster version
		@Read_DSP
		MOV		AH,AL
		@Read_DSP
		CMP		AH,3	 ; Sbpro version is 3
		JNE		NEAR .SoundError
		; Initialize Mixer
		@Write_Mixer 0,0
		; detect IRQ
.IRQDetected:	MOV		EAX,[EBP+IRQ] ; IRQ default 5
		CALL		GetBaseAddress
		MOV		[EBX+SB_IRQ],EAX
		MOV		[EBX+SbIRQ],EAX
		; detect DMA 8Bits
.DMA8Detect:	MOV		EAX,[EBP+DMA8] ; DMA 8 bits default 1
		CALL		GetBaseAddress
		MOV		[EBX+SB_DMA8],EAX
		MOV		[EBX+SbDMA8],EAX
		; Allocation Des Buffers DMA---------------------------------
		
		@AllocDOSMemDMA8 SizeDMABuff
		OR		EAX,EAX
		JZ		NEAR .SoundError
		
		CALL		GetBaseAddress
		MOV		EAX,[EBX+PhysAddDMA8]
		MOV		ESI,EAX
		AND		EAX,0xffff
		MOV		[EBX+OffDMA8],EAX
		SHR		ESI,16
		MOV		[EBX+PageDMA8],ESI

		; Install the new IRQ Handler-------------------------------
		CLI

		CALL		GetBaseAddress
		MOV		AX,0x204 ; Get Old SB_IRQ Handler
		MOV		EBX,[EBX+SbIRQ]
		CMP		BL,8
		JAE		.GetPIC2
		ADD		BL,8
		JMP		SHORT .GetPIC1
.GetPIC2:	ADD		BL,0x70-8
.GetPIC1:
		INT		0x31
		CALL		GetBaseAddress

		MOV		[EBX+OldHdSndOff],EDX
		MOV		[EBX+OldHdSndSeg],ECX

		XOR		EAX,EAX
		IN		AL,0x21
		MOV		[EBX+Old0x21],EAX
		IN		AL,0xA1
		MOV		[EBX+Old0xA1],EAX
		MOV		EDI,[EBX+SbIRQ]
		XOR		ESI,ESI    ; 0x21
		XOR		EDX,EDX    ; 0xA1
		MOV		ECX,EDI
		CMP		CL,8
		JAE		.IRQContr2
.IRQContr1:	MOV		ESI,1
		SHL		ESI,CL
		JMP		SHORT .PasContr2
.IRQContr2:	SUB		ECX,8
		MOV		ESI,4
		MOV		EDX,1
		SHL		EDX,CL
.PasContr2:	NOT		EDX
		NOT		ESI
		AND		EDX,[EBX+Old0xA1]
		AND		ESI,[EBX+Old0x21]
		MOV		EAX,EDX
		OUT		0xA1,AL
		MOV		EAX,ESI
		OUT		0x21,AL

		MOV		AX,0x205 ; Set New SB_IRQ Handler
		MOV		EDX,SB_Handler  ; offset SB_Handler
		ADD		EDX,EBX         ; + Base Address
		MOV		EBX,[EBX+SbIRQ]
		CMP		BL,8
		JAE		.InstPIC2
		ADD		BL,8
		JMP		SHORT .InstPIC1
.InstPIC2:	ADD		BL,0x70-8
.InstPIC1:
		MOV		ECX,CS
		INT		0x31
		JNC		.SetHandlerOk
		CALL		GetBaseAddress
		MOV		EAX,[EBX+Old0x21]
		OUT		0x21,AL
		MOV		EAX,[EBX+Old0xA1]
		OUT		0xA1,AL
		STI
		JMP		.SoundError
.SetHandlerOk:	STI
		; Get DS Base Address----------------------------------------
		MOV		AX,6
		MOV		BX,DS
		INT		0x31
		SHL		ECX,16
		AND		EDX,0xffff
		CALL		GetBaseAddress
		OR 		EDX,ECX
		MOV		[EBX+DSBaseAddress],EDX
		MOV		EAX,DS	     ; sauvegarde DS
		MOV		[EBX+SndMyDSSelector],EAX
		; lock code--------------------------------------------------
		MOV		AX,0x600
		MOV		ECX,DebSndLockCode     ; LOW WORD LAddr
		ADD		ECX,[EBX+DSBaseAddress]
		ADD		ECX,EBX ; + Base Address
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinSndLockCode-DebSndLockCode+1)
		MOV		ESI,(FinSndLockCode-DebSndLockCode+1)>>16
		INT		0x31
		JC		NEAR .SoundError
		; lock data--------------------------------------------------
		CALL		GetBaseAddress
		MOV		AX,0x600
		MOV		ECX,DebSndLockData     ; LOW WORD LAddr
		ADD		ECX,[EBX+DSBaseAddress]
		ADD		ECX,EBX ; + Base Address
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinSndLockData-DebSndLockData+1)
		MOV		ESI,((FinSndLockData-DebSndLockData+1)>>16)
		INT		0x31
		JC		NEAR .SoundError
		; lock Buff--------------------------------------------------
		CALL		GetBaseAddress
		MOV		AX,0x600 ; DPMI lock
		MOV		ECX,[EBP+PtrBuff]    ; LOW WORD LAddr
		MOV		[EBX+BuffPtr],ECX    ; sauvegarde l'adresse
		MOV		[EBX+BuffCalc8Bit],ECX    ; sauvegarde l'adresse
		ADD		ECX,SizeDMABuff*2
		MOV		[EBX+TempVcCopyBuff],ECX
		ADD		ECX,SizeDMABuff*2
		MOV		[EBX+EffectVcBuff],ECX

		MOV		ECX,[EBX+BuffPtr]
		ADD		ECX,[EBX+DSBaseAddress]
		MOV		EDI,[EBX+SizeBuff]
		MOV		ESI,[EBX+SizeBuff]
		SHR		ESI,16
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		INT		0x31
		JC		NEAR .SoundError

		JMP		SHORT .SoundOk
.SoundError:	XOR		EAX,EAX
		JMP		NEAR .PasSndOk
.SoundOk:	OR		EAX,BYTE -1
.PasSndOk:
		POP		EBX
		POP		EDI
		POP		ESI
		RETURN

UninstallDriver:
		PUSH		ESI
		PUSH		EDI
		PUSH		EBX

		; stop SOUND and DMA 8Bits ----------------------------------
		@Write_DSP 0xD0 ; Halt DMA 8bits oper
		@Write_DSP 0xD3 ; disable speaker
		@Write_DSP 0xDA ; Exit Auto-Init DMA 8Bits oper
		@StopDMA8 ; Stop DMA
		; restore old interrupt handler SB_IRQ-----------------------
		CLI
		CALL		GetBaseAddress
		MOV		EAX,[EBX+Old0xA1]
		OUT		0xA1,AL
		MOV		EAX,[EBX+Old0x21]
		OUT		0x21,AL

		MOV		AX,0x205 ; Restore Old SB_IRQ Handler
		MOV		EDX,[EBX+OldHdSndOff]
		MOV		ECX,[EBX+OldHdSndSeg]
		MOV		EBX,[EBX+SbIRQ]
		CMP		EBX,8
		JAE		.InstPIC2
		ADD		EBX,8
		JMP		SHORT .InstPIC1
.InstPIC2:	ADD		EBX,0x70-8
.InstPIC1:
		INT		0x31
		
		STI
		
		; free buffer DMA 8Bits--------------------------------------
		CALL		GetBaseAddress
		MOV		AX,0x101
		MOV		EDX,[EBX+SelectorDMA8]
		INT		0x31
		; unlock code------------------------------------------------
		CALL		GetBaseAddress
		MOV		AX,0x601 ; DPMI unlock
		MOV		ECX,DebSndLockCode     ; LOW WORD LAddr
		ADD		ECX,[EBX+DSBaseAddress]
		ADD		ECX,EBX ; + Base Address
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinSndLockCode-DebSndLockCode+1)
		MOV		ESI,(FinSndLockCode-DebSndLockCode+1)>>16
		INT		0x31
		; unlock data------------------------------------------------
		CALL		GetBaseAddress
		MOV		AX,0x601 ; DPMI unlock
		MOV		ECX,DebSndLockData     ; LOW WORD LAddr
		ADD		ECX,[EBX+DSBaseAddress]
		ADD		ECX,EBX ; + Base Address
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		MOV		EDI,(FinSndLockData-DebSndLockData+1)
		MOV		ESI,(FinSndLockData-DebSndLockData+1)>>16
		INT		0x31
		; unlock Buff------------------------------------------------
		CALL		GetBaseAddress
		MOV		AX,0x601 ; DPMI unlock
		MOV		ECX,[EBX+BuffPtr]    ; LOW WORD LAddr
		ADD		ECX,[EBX+DSBaseAddress]
		MOV		EDI,[EBX+SizeBuff]
		MOV		ESI,[EBX+SizeBuff]
		SHR		ESI,16
		MOV		EBX,ECX     ; HIGH WORD LAddr
		SHR		EBX,16
		INT		0x31

		POP		EBX
		POP		EDI
		POP		ESI
		RET

		
SECTION .data
; DONNEE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OldHdSndOff		DD	0
OldHdSndSeg		DD	0
DSBaseAddress		DD	0
Old0x21			DD	0
Old0xA1			DD	0
DebSndLockData:;*************************************************************
SndMyDSSelector		DD	0
BuffPtr			DD	0
PhysAddDMA8		DD	0
SelectorDMA8		DD	0
OffDMA8			DD	0
PageDMA8		DD	0
OffResCalcDMA8		DD	0
PhysAddDMA16		DD	0
SelectorDMA16		DD	0
OffDMA16		DD	0
PageDMA16		DD	0
OffResCalcDMA16		DD	0
SbBase			DD	0
SbIRQ			DD	0
SbDMA8			DD	0
SbDMA16 		DD	0
SbSampSpeed		DD	0
MixerIndex		DD	0
MixerData		DD	0
DSPReset		DD	0
DSPData			DD	0
DSPStateCommand		DD	0
DSPStateAck8		DD	0
DSPAck16		DD	0
State16Bits		DD	0
State8Bits		DD	0
OutType			DD	0
InType			DD	0
BuffCalc8Bit		DD	0
BuffCalc16Bit		DD	0
TempVcCopyBuff		DD	0
EffectVcBuff		DD	0
;-----Pointer Function --
AddrProced8Bit		DD	0
;------Voices Data Out ---
MaxNbVoice		DD	32
VoicePtr:		DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
WaitVoicePtr:		DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			DD	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;------Voice Data In -----
RecordState		DD	0
RecordBuffPtr		DD	0
RecordNbBloc		DD	0
RecordSizeBloc		DD	0
Record1stBlocPtr	DD	0
;------Adresses of functions of mixing a voice with the main Buffer
AddrProcAddBCalc:
AddrAdd_BCalc8BitM:	DD	AddVc8BitM_BCalc8BitM,AddVc8BitS_BCalc8BitM
			DD	AddVc16BitM_BCalc8BitM,AddVc16BitS_BCalc8BitM
AddrAdd_BCalc8BitS:	DD	AddVc8BitM_BCalc8BitS,AddVc8BitS_BCalc8BitS
			DD	AddVc16BitM_BCalc8BitS,AddVc16BitS_BCalc8BitS
BuffVc_SpeedBuffVc:	DD	Buff8BitM_SpeedBuff8BitM
			DD	Buff8BitS_SpeedBuff8BitS
                        
SizeIncVc_BCalc:
SizeIncVc_BCalc8BitM:	DD	SizeDMABuff/2,SizeDMABuff
			DD	SizeDMABuff,SizeDMABuff*2
SizeIncVc_BCalc8BitS:	DD	SizeDMABuff/4,SizeDMABuff/2
			DD	SizeDMABuff/2,SizeDMABuff
SizeEchant:		DD	1,2,2,4
FinSndLockData:;*************************************************************

; CONST ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ----- Capabilities ----------------
Out8			EQU	1
Out16			EQU	2
OutMono			EQU	4
OutStereo		EQU	8
In8			EQU	16
In16			EQU	32
InMono			EQU	64
InStereo		EQU	128
FullDuplex		EQU	256
; -----------------------------------
SizeDMABuff		EQU	512   ; pow of 2
VolMask			EQU	0x1ff    ; 63 Vol Norm
SpeedMask		EQU	0x7ff	 ; 128 speed Norm
; ----- Effect ----------------------
ChgSpeed		EQU	1
ChgVol			EQU	2
;VcReverse		EQU	4
; ----- Voice State -----------------
VcInBoucle		EQU	1
VcStopped		EQU	2
; sound card name ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CardName		DB	"Sound Blaster Pro or 100% compatible",0
FinDrv:

