#!/usr/bin/env bash
export DEPENDENCIES="java jq ffmpeg bc curl csvtool"
export ERROR="1"
export INFO="1"
export DEBUG="1"

if [[ "${DEBUG}" == "1" ]] ; then
    FFMPEG_OPTS="-hide_banner"
else
    FFMPEG_OPTS="-hide_banner -loglevel error"
fi
export FFMPEG_OPTS
#reduces time of output videos to 1s, encode to aprox. 20sec
#export FFMPEG_DEBUG_OPTS="-t 10"
export FFMPEG_DEBUG_OPTS=""

WORKING_FOLDER=$(mktemp -d -p "/tmp/" \
    -t "gopro-$(date +%Y-%m-%d_%H.%M.%S)-XXXXXXXXXX")
export WORKING_FOLDER

#export GOPRO_CLIPS_FOLDER="$HOME/gopro/Samples/2021-07-31_indoors3/GOPRO/"
GOPRO_PATH="/run/user/1000/gvfs/mtp:host=GoPro_HERO7_C3281328000793/"
GOPRO_PATH+="GoPro MTP Client Disk Volume/DCIM/100GOPRO/"
ln -s "${GOPRO_PATH}" "${WORKING_FOLDER}/link_to_GoPro"
GOPRO_CLIPS_FOLDER="${WORKING_FOLDER}/link_to_GoPro"
#GOPRO_CLIPS_FOLDER="$HOME/gopro/Samples/GoPro/2021-08-15.1/"
export GOPRO_CLIPS_FOLDER
export GARMIN_FITCSVTOOL_JAR="$HOME/gopro/Garmin_FitSDK/java/FitCSVTool.jar"
#export GPS_LOGS_FOLDER="$HOME/gopro/Samples/Garmin/"
export GPS_LOGS_FOLDER="/media/pi/GARMIN/GARMIN/ACTIVITY/"
export GPS_LOGS_NAME_PATTERN="*.FIT"
export GOPRO_DATE_ADJUSTMENT_SEC=$((-2 * 3600))
SECONDS_BETWEEN_UNIX_AND_GARMIN_EPOCH=$(date -d 'UTC 00:00 Dec31 1989' '+%s')
export SECONDS_BETWEEN_UNIX_AND_GARMIN_EPOCH

export DATAFIELD_CADENCE="1"
export DATAFIELD_DISTANCE="2"
export DATAFIELD_GRADE="3"
export DATAFIELD_SPEED="4"
export DATAFIELD_HEARTRATE="5"
export DRAWTEXT_FORMAT='
fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf:
fontsize=20:
fontcolor=white:
box=1:
boxcolor=black@0.7:
boxborderw=10:
x=10:
y=main_h-(6*line_h)-10:
'
export FTP_HOSTNAME="vps719805.ovh.net"
export FTP_PORT="21"
export FTP_USERNAME="axis-camera"
export FTP_PASSWORD_BASE64="JGI3QDhlUk4jdlk="
