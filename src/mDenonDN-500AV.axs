MODULE_NAME='mDenonDN-500AV'    (
                                    dev vdvObject,
                                    dev dvPort
                                )

(***********************************************************)
#include 'NAVFoundation.Core.axi'
#include 'NAVFoundation.ArrayUtils.axi'
#include 'NAVFoundation.Math.axi'

/*
 _   _                       _          ___     __
| \ | | ___  _ __ __ _  __ _| |_ ___   / \ \   / /
|  \| |/ _ \| '__/ _` |/ _` | __/ _ \ / _ \ \ / /
| |\  | (_) | | | (_| | (_| | ||  __// ___ \ V /
|_| \_|\___/|_|  \__, |\__,_|\__\___/_/   \_\_/
                 |___/

MIT License

Copyright (c) 2023 Norgate AV Services Limited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
constant long TL_DRIVE    = 1

constant sinteger MAX_LEVEL = 98
constant sinteger MIN_LEVEL = 0

constant integer POWER_STATE_ON    = 1
constant integer POWER_STATE_OFF    = 2

constant char INPUT_COMMANDS[][NAV_MAX_CHARS]    =  {
                                                        'CD',
                                                        'DVD',
                                                        'BD',
                                                        'TV',
                                                        'SAT/CBL',
                                                        'GAME',
                                                        'GAME2',
                                                        'DOCK',
                                                        'V.AUX',
                                                        'IPOD',
                                                        'NET/USB',
                                                        'SERVER',
                                                        'FAVOURITES',
                                                        'USB/IPOD',
                                                        'USB',
                                                        'IPD',
                                                        'MPLAY'
                                                    }

constant char SURROUND_MODE_COMMANDS[][NAV_MAX_CHARS]    =  {
                                                                'MOVIE',
                                                                'MUSIC',
                                                                'GAME',
                                                                'DIRECT',
                                                                'PURE DIRECT',
                                                                'STEREO',
                                                                'AUTO',
                                                                'DOLBY DIGITAL',
                                                                'DTS SURROUND',
                                                                'AURO3D',
                                                                'AURO2DSURR',
                                                                'MCH STEREO',
                                                                'WIDE SCREEN',
                                                                'SUPER STADIUM',
                                                                'ROCK ARENA',
                                                                'JAZZ CLUB',
                                                                'CLASSIC CONCERT',
                                                                'MONO MOVIE',
                                                                'MATRIX',
                                                                'VIDEO GAME',
                                                                'VIRTUAL'
                                                            }

constant integer GET_POWER    = 1
constant integer GET_INPUT    = 2
constant integer GET_VOL    = 3
constant integer GET_MUTE    = 4
constant integer GET_SURROUND_MODE = 5

constant integer MUTE_STATE_ON    = 1
constant integer MUTE_STATE_OFF    = 2


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
volatile integer iSemaphore
volatile char cRxBuffer[NAV_MAX_BUFFER]

volatile integer iLoop
volatile integer iPollSequence = GET_POWER

volatile long iDrive[] = { 200 }

volatile integer iRequiredPower
volatile integer iRequiredInput
volatile integer iRequiredMute
volatile sinteger iRequiredVolume
volatile integer iRequiredSurroundMode

volatile integer iActualPower
volatile integer iActualInput
volatile integer iActualMute
volatile sinteger iActualVolume
volatile integer iActualSurroundMode

volatile integer iActualPowerInitialized
volatile integer iActualInputInitialized
volatile integer iActualMuteInitialized
volatile integer iActualVolumeInitialized
volatile integer iActualSurroundModeInitialized
volatile integer iFeedbackInitialized

volatile integer iCommandLockOut

(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
define_function SendStringRaw(char cPayload[]) {
    NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'String To ', NAVConvertDPSToAscii(dvPort), '-[', cPayload, ']'")
    send_string dvPort, "cPayload"
}


define_function SendString(char cPayload[]) {
    SendStringRaw("cPayload, NAV_CR")
}


define_function SendQuery(integer iQuery) {
    switch (iQuery) {
        case GET_POWER: {
            SendString("'ZM?'")
        }
        case GET_INPUT: {
            SendString("'SI?'")
        }
        case GET_VOL: {
            SendString("'MV?'")
        }
        case GET_MUTE: {
            SendString("'MU?'")
        }
        case GET_SURROUND_MODE: {
            SendString("'MS?'")
        }
    }
}


define_function TimeOut() {
    [vdvObject, DEVICE_COMMUNICATING] = TRUE
    cancel_wait 'CommsTimeOut'
    wait 300 'CommsTimeOut' { [vdvObject, DEVICE_COMMUNICATING] = FALSE }
}


define_function SetPower(integer iState) {
    switch(iState) {
        case POWER_STATE_ON: { SendString("'ZMON'") }
        case POWER_STATE_OFF: { SendString("'ZMOFF'") }
    }
}


define_function SetVolume(sinteger iLevel) { SendString("'MV', format('%02d', iLevel)") }


define_function SetMute(integer iState) {
    switch (iState) {
        case MUTE_STATE_ON: { SendString("'MUON'") }
        case MUTE_STATE_OFF: { SendString("'MUOFF'") }
    }
}


define_function SetInput(integer iInput) { SendString("'SI', INPUT_COMMANDS[iInput]") }


define_function SetSurroundMode(integer iSurroundMode) { SendString("'MS', SURROUND_MODE_COMMANDS[iSurroundMode]") }


define_function RampVolume(integer iParam) {
    switch (iParam) {
        case VOL_UP: { SendString("'MVUP'") }
        case VOL_DN: { SendString("'MVDOWN'") }
    }
}


define_function Process() {
    stack_var char cTemp[NAV_MAX_BUFFER]

    iSemaphore = TRUE

    while (length_array(cRxBuffer) && NAVContains(cRxBuffer, "NAV_CR")) {
        cTemp = remove_string(cRxBuffer, "NAV_CR", 1)

        if (length_array(cTemp)) {
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'Gathered String From ', NAVConvertDPSToAscii(dvPort), '-[', cTemp, ']'")

            cTemp = NAVStripCharsFromRight(cTemp, 1)

            select {
                active (NAVContains(cTemp, "'ZM'")): {
                    remove_string(cTemp, 'ZM', 1)

                    switch (cTemp) {
                        case 'OFF': { iActualPower = POWER_STATE_OFF }
                        case 'ON': { iActualPower = POWER_STATE_ON }
                    }

                    iActualPowerInitialized = TRUE

                    iPollSequence = GET_INPUT
                }
                active (NAVContains(cTemp, "'SI'")): {
                    remove_string(cTemp, 'SI', 1)

                    iActualInput = NAVFindInArraySTRING(INPUT_COMMANDS, cTemp)
                    iActualInputInitialized = TRUE
                    iPollSequence = GET_VOL
                }
                active (NAVContains(cTemp, "'MV'")): {
                    remove_string(cTemp, 'MV', 1)

                    if (!NAVContains(cTemp, 'MAX')) {
                        if (length_array(cTemp) > 2) {
                            // The third number represents the floating point
                            // value.  We don't care about it, so we'll just
                            // remove it.
                            cTemp = NAVStripCharsFromRight(cTemp, 1)
                        }

                        switch (cTemp) {
                            default: {
                                iActualVolume = atoi(cTemp)
                            }
                        }

                        send_level vdvObject, 1, NAVScaleValue((iActualVolume - MIN_LEVEL),
                                                                (MAX_LEVEL - MIN_LEVEL),
                                                                255,
                                                                0)
                        iActualVolumeInitialized = TRUE
                        iPollSequence = GET_MUTE
                    }
                }
                active (NAVContains(cTemp, "'MU'")): {
                    remove_string(cTemp, 'MU', 1)

                    switch (cTemp) {
                        case 'OFF': { iActualMute = MUTE_STATE_OFF }
                        case 'ON': { iActualMute = MUTE_STATE_ON }
                    }

                    iActualMuteInitialized = TRUE
                    iPollSequence = GET_POWER
                }
                active (NAVContains(cTemp, "'MS'")): {
                    stack_var integer iSurroundMode

                    remove_string(cTemp, 'MS', 1)

                    iSurroundMode = NAVFindInArraySTRING(SURROUND_MODE_COMMANDS, cTemp)

                    if (iSurroundMode != iActualSurroundMode) {
                        iActualSurroundMode = iSurroundMode
                        send_string vdvObject, "'SURROUND_MODE-', SURROUND_MODE_COMMANDS[iActualSurroundMode]"
                    }

                    iActualSurroundModeInitialized = TRUE
                    iPollSequence = GET_POWER
                }
            }
        }
    }

    iSemaphore = FALSE
}


define_function Drive() {
    iLoop++

    [vdvObject, DATA_INITIALIZED] = (iActualPowerInitialized && iActualInputInitialized && iActualVolumeInitialized && iActualMuteInitialized)

    switch(iLoop) {
        case 1:
        case 6:
        case 11:
        case 16: { if (![vdvObject, DATA_INITIALIZED]) SendQuery(iPollSequence); return }
        case 21: { if (![vdvObject, DATA_INITIALIZED]) iLoop = 1; return }
        case 50: { if ([vdvObject, DATA_INITIALIZED]) SendQuery(iPollSequence); iLoop = 0; return }
        default: {
            if (iCommandLockOut) return

            if (iRequiredPower && (iRequiredPower == iActualPower)) { iRequiredPower = 0; return }
            if (iRequiredInput && (iRequiredInput == iActualInput)) { iRequiredInput = 0; return }
            if (iRequiredVolume && (iRequiredVolume == iActualVolume)) { iRequiredVolume = 0; return }
            if (iRequiredMute && (iRequiredMute == iActualMute)) { iRequiredMute = 0; return }

            if (iRequiredPower && (iRequiredPower != iActualPower)) {
                SetPower(iRequiredPower); iCommandLockOut = TRUE; wait 50 iCommandLockOut = FALSE; iActualPowerInitialized = FALSE; iPollSequence = GET_POWER; return
            }

            if (iRequiredInput && (iActualPower == POWER_STATE_ON) && (iRequiredInput != iActualInput)) {
                SetInput(iRequiredInput); iCommandLockOut = TRUE; wait 20 iCommandLockOut = FALSE; iActualInputInitialized = FALSE; iPollSequence = GET_INPUT; return
            }

            if (iRequiredMute && (iActualPower == POWER_STATE_ON) && (iRequiredMute != iActualMute)) {
                SetMute(iRequiredMute); iCommandLockOut = TRUE; wait 20 iCommandLockOut = FALSE; iActualMuteInitialized = FALSE; iPollSequence = GET_MUTE; return
            }

            if (iRequiredSurroundMode && (iActualPower == POWER_STATE_ON) && (iRequiredSurroundMode != iActualSurroundMode)) {
                SetSurroundMode(iRequiredSurroundMode); iCommandLockOut = TRUE; wait 20 iCommandLockOut = FALSE; iActualSurroundModeInitialized = FALSE; iPollSequence = GET_SURROUND_MODE; return
            }

            if  ([vdvObject,VOL_UP]) { RampVolume(VOL_UP) }
            if  ([vdvObject,VOL_DN]) { RampVolume(VOL_DN) }
        }
    }
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {
    create_buffer dvPort, cRxBuffer
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[dvPort] {
    online: {
        send_command data.device, "'SET MODE DATA'"
        send_command data.device, "'SET BAUD 9600,N,8,1 485 DISABLE'"
        send_command data.device, "'B9MOFF'"
        send_command data.device, "'CHARD-0'"
        send_command data.device, "'CHARDM-0'"
        send_command data.device, "'HSOFF'"

        NAVTimelineStart(TL_DRIVE, iDrive, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
    }
    string: {
        TimeOut()
        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'String From ', NAVConvertDPSToAscii(dvPort), '-[', data.text, ']'")
        if(!iSemaphore) { Process() }
    }
}


data_event[vdvObject] {
    command: {
        stack_var char cCmdHeader[NAV_MAX_CHARS]
        stack_var char cCmdParam[2][NAV_MAX_CHARS]

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'Command From ', NAVConvertDPSToAscii(data.device), '-[', data.text, ']'")

        cCmdHeader = DuetParseCmdHeader(data.text)
        cCmdParam[1] = DuetParseCmdParam(data.text)
        cCmdParam[2] = DuetParseCmdParam(data.text)

        switch (cCmdHeader) {
            case 'PROPERTY': {
                switch (cCmdParam[1]) {
                    case 'IP_ADDRESS': {}
                    case 'TCP_PORT': {}
                }
            }
            case 'REINIT': {}
            case 'PASSTHRU': { SendString(cCmdParam[1]) }
            case 'POWER': {
                switch (cCmdParam[1]) {
                    case 'ON': { iRequiredPower = POWER_STATE_ON }
                    case 'OFF': { iRequiredPower = POWER_STATE_OFF; iRequiredInput = 0; iRequiredMute = 0 }
                }
            }
            case 'INPUT': {
                stack_var integer iInput

                iInput = NAVFindInArraySTRING(INPUT_COMMANDS, cCmdParam[1])

                if (iInput) {
                    iRequiredPower = POWER_STATE_ON
                    iRequiredInput = iInput
                }
            }
            case 'MUTE': {
                switch (cCmdParam[1]) {
                    case 'ON': { iRequiredMute = MUTE_STATE_ON }
                    case 'OFF': { iRequiredMute = MUTE_STATE_OFF }
                }
            }
            case 'VOLUME': {
                if (iActualPower == POWER_STATE_ON) {
                    switch (cCmdParam[1]) {
                        case 'ABS': {
                            iRequiredVolume = atoi(cCmdParam[2])
                            SetVolume(iRequiredVolume)
                        }
                        default: {
                            iRequiredVolume = atoi(cCmdParam[1]) * (MAX_LEVEL - MIN_LEVEL) / 255
                            SetVolume(iRequiredVolume)
                        }
                    }
                }
            }
            case 'SURROUND_MODE': {
                if (iActualPower == POWER_STATE_ON) {
                    stack_var integer iSurroundMode

                    iSurroundMode = NAVFindInArraySTRING(SURROUND_MODE_COMMANDS, cCmdParam[1])

                    if (iSurroundMode) {
                        iRequiredSurroundMode = iSurroundMode
                    }
                }
            }
        }
    }
}


channel_event[vdvObject, 0] {
    on: {
        switch (channel.channel) {
            case POWER: {
                if (iRequiredPower) {
                    switch (iRequiredPower) {
                        case POWER_STATE_ON: { iRequiredPower = POWER_STATE_OFF; iRequiredInput = 0; iRequiredMute = 0 }
                        case POWER_STATE_OFF: { iRequiredPower = POWER_STATE_ON }
                    }
                } else {
                    switch (iActualPower) {
                        case POWER_STATE_ON: { iRequiredPower = POWER_STATE_OFF; iRequiredInput = 0; iRequiredMute = 0 }
                        case POWER_STATE_OFF: { iRequiredPower = POWER_STATE_ON }
                    }
                }
            }
            case PWR_ON: { iRequiredPower = POWER_STATE_ON }
            case PWR_OFF: { iRequiredPower = POWER_STATE_OFF; iRequiredInput = 0; iRequiredMute = 0 }
            case VOL_UP: {}
            case VOL_DN: {}
            case VOL_MUTE: {
                if (iRequiredMute) {
                    switch (iRequiredMute) {
                        case MUTE_STATE_ON: { iRequiredMute = MUTE_STATE_OFF }
                        case MUTE_STATE_OFF: { iRequiredMute = MUTE_STATE_ON }
                    }
                } else {
                    switch (iActualMute) {
                        case MUTE_STATE_ON: { iRequiredMute = MUTE_STATE_OFF }
                        case MUTE_STATE_OFF: { iRequiredMute = MUTE_STATE_ON }
                    }
                }
            }
            case VOL_MUTE_ON: {
                if (iActualPower == POWER_STATE_ON) {
                    iRequiredMute = MUTE_STATE_ON
                }
            }
        }
    }
    off: {
        switch (channel.channel) {
            case VOL_MUTE_ON: {
                if (iActualPower == POWER_STATE_ON) {
                    iRequiredMute = MUTE_STATE_OFF
                }
            }
        }
    }
}


timeline_event[TL_DRIVE] { Drive() }


timeline_event[TL_NAV_FEEDBACK] {
    [vdvObject, POWER_FB]    = (iActualPower == POWER_STATE_ON)
    [vdvObject, VOL_MUTE_FB] = (iActualMute == MUTE_STATE_ON)
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
