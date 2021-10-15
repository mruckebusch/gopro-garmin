#!/usr/bin/env bash

#Adds overlay text to a video file, using ffmpeg sendcmd filter
#see documentation: http://ffmpeg.org/ffmpeg-filters.html#sendcmd_002c-asendcmd
#$1 the clip file path
#$2 the ffmpeg cmd file path
#Outputs to STDOUT the new clip file path
function _sendcmd_to_overlay {
    local clip
    clip="$1"
    local ffmpeg_cmd
    ffmpeg_cmd="$2"

    if [[ -s "${ffmpeg_cmd}" ]]; then
    local output_video
    output_video=$(basename "${clip}")
    output_video="${WORKING_FOLDER}/${output_video}_with_overlay.mp4"
        local ffmpeg_command
    ffmpeg_command="ffmpeg ${FFMPEG_OPTS} \
    ${FFMPEG_DEBUG_OPTS} \
    -i \"${clip}\"       \
    -vf \"sendcmd=f=${ffmpeg_cmd},drawtext=text=:${DRAWTEXT_FORMAT}\" \
    \"${output_video}\""
    __msg_debug "ffmpeg_command=${ffmpeg_command}"
    eval "${ffmpeg_command}"
    clip="${output_video}"
    fi
    echo "${clip}"
}

#Concatenates multiple video clips into one video clip
# $1 the output video path
# $@ clips to concatenate (array)
#Outputs to STDOUT/STDERR ffmpeg various outputs
function _concatenate_clips {
    local output
    output="$1"
    __msg_debug "output=${output}"
    shift

    local file_list_inputs
    file_list_inputs=$(mktemp  -p "${WORKING_FOLDER}" \
        -t "clips_to_concat-$(date +%Y-%m-%d_%H.%M.%S).XXX")

    #TODO shorten array writing with printf
    # printf "file '%s'\n" "$@" > "${file_list_inputs}"
    # https://trac.ffmpeg.org/wiki/Concatenate
    for clip in "$@"; do
        __msg_debug "clip : ${clip}"
        echo "file '${clip}'" >> "${file_list_inputs}"
    done

    local ffmpeg_command
    ffmpeg_command="ffmpeg  \
            ${FFMPEG_OPTS}           \
            -f concat -safe 0            \
        -i ${file_list_inputs}       \
        -c copy ${output}"

    __msg_debug "ffmpeg_command=${ffmpeg_command}"
    eval "${ffmpeg_command}"
}



# shows the format of a clip, formatted in json
# $1 the clip path
function ___get_clip_format {
    ffprobe -loglevel error     \
        -print_format json  \
        -show_format    \
        "$1"
}


# shows the duration of a clip in seconds
# $1 the clip path
function __get_clip_duration_seconds {
    local ret
    ret=$(___get_clip_format "$1" | jq -r '.format.duration')
    # rounds duration down to the second (quotient)
    # I use bc instead of bash arithmetic operation because it's a float number
    ret=$(bc <<< "${ret} / 1")
    echo "${ret}"
}

# Shows the start date of a clip in format yyyy-MM-dd
# $1 the clip path
function __get_clip_start_date_iso {
    local ret
    ret=$(___get_clip_format "$1" | jq -r '.format.tags.creation_time')
    echo "${ret:0:10}"
}

# Shows the start date of a clip in seconds
# $1 the clip path
function __get_clip_start_date {
    local ret
    ret=$(___get_clip_format "$1" | jq -r '.format.tags.creation_time')

    ret=$(___date_to_seconds "$ret")

    ret=$((ret + GOPRO_DATE_ADJUSTMENT_SEC))
    echo "${ret}"
}

# Shows the end date of a clip
# $1 the clip path
function __get_clip_end_date {
    local clip_start_date
    clip_start_date=$(__get_clip_start_date "$1")

    local clip_duration
    clip_duration=$(__get_clip_duration_seconds "$1")

    local clip_end_date
    clip_end_date=$((clip_start_date + clip_duration))
    echo "${clip_end_date}"
}

# Uploads a video clip to FTP server
# $1 - local path of the clip to upload
function _upload_clip {
    local clip_path
    clip_path="$1"
    local ftp_password
    ftp_password=$(base64 -d <<< "${FTP_PASSWORD_BASE64}")
    curl --silent --user "${FTP_USERNAME}":"${ftp_password}" \
         --upload-file "${clip_path}" ftp://"${FTP_HOSTNAME}"
}
