#!/usr/bin/env bash
source constants.sh
source logging.sh
source dates.sh
source video.sh
source gps.sh
source misc.sh

#exits the script when a command fails
set -o errexit
#add || true to commands that you allow to fail.

# exit the script when using undeclared variables.
set -o nounset

trap exit_trap 0 SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
trap err_trap ERR

#Iterates through all days found in GoPro folder.
# for each clip, add GPS data (text overlay) if Garmin GPS devise is mounted.
# then create a concatenated output_video and upload it to a remote server.
function main {
#set -x
    _set_xtrace_ps4
    _verify_dependencies

    for day in $(_list_days_files_in_dir "${GOPRO_CLIPS_FOLDER}"); do
        __msg_debug "iteration of day ${day}"
        local output_video
        output_video="${WORKING_FOLDER}/${day}.mp4"
        declare -a gps_logs_fit
        gps_logs_fit=()
        for log in $(_get_fit_files_with_date \
                "${GPS_LOGS_FOLDER}" "${day}"); do
            __msg_debug "log=${log}"
            gps_logs_fit+=("${log}")
        done
        #TODO fixme replace __fit_to_csv_records with _fit_to_csv_records_day
        _fit_to_csv_records_day "${day}" "${gps_logs_fit[@]}"
        declare -a clips_to_concatenate
        clips_to_concatenate=()
        local elapsed_offset
        elapsed_offset=0
        for clip in $(_get_clip_files_with_date \
                "${GOPRO_CLIPS_FOLDER}" "${day}"); do
            __msg_debug "clip=${clip}"
            if _is_garmin_mounted ; then
                local ffmpeg_cmd
                ffmpeg_cmd=$(_convert_fit_to_drawtext_cmd \
                    "${clip}"   \
                    "${elapsed_offset}" \
                    "${gps_logs_fit[@]}")

                __msg_debug "ffmpeg_cmd=${ffmpeg_cmd}"
                if [[ -s "${ffmpeg_cmd}" ]]; then
                    #override clip with the overlay version:
                    clip=$(_sendcmd_to_overlay "${clip}" "${ffmpeg_cmd}")
                fi
            fi
            clips_to_concatenate+=("${clip}")
            __msg_debug "clips_to_concatenate=${clips_to_concatenate[*]}"
            elapsed_offset=$((
                elapsed_offset
                +
                $(__get_clip_duration_seconds "${clip}")
                ))
        done
        _concatenate_clips "${output_video}" "${clips_to_concatenate[@]}"
        rm -f "${clips_to_concatenate[@]}"
        _upload_clip "${output_video}"
        rm -f "${output_video}"

    done
}
main
